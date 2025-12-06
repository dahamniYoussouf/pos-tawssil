import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/menu_item.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/print_service.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  final PrintService _printer = PrintService();

  Order? _currentOrder;
  String? _selectedCashierId;
  bool _isProcessing = false;

  Order? get currentOrder => _currentOrder;
  String? get selectedCashierId => _selectedCashierId;
  bool get isProcessing => _isProcessing;
  double get total => _currentOrder?.totalAmount ?? 0.0;
  int get itemCount => _currentOrder?.items.length ?? 0;

  // ========== CASHIER SELECTION ==========
  
  void selectCashier(String cashierId) {
    _selectedCashierId = cashierId;
    _startNewOrder();
    notifyListeners();
  }

  void _startNewOrder() {
    final uuid = Uuid();
    final now = DateTime.now();
    final orderNumber = 'POS-${now.year}${now.month}${now.day}-${now.millisecondsSinceEpoch % 10000}';

    _currentOrder = Order(
      id: uuid.v4(),
      orderNumber: orderNumber,
      cashierId: _selectedCashierId!,
      restaurantId: '', // Will be set from API
      orderType: 'pickup',
      subtotal: 0,
      totalAmount: 0,
      paymentMethod: 'cash_on_delivery',
      status: 'pending',
      items: [],
      createdAt: now,
      updatedAt: now,
      synced: false,
    );
  }

  // ========== ORDER MANAGEMENT ==========
  
  void addItem(MenuItem menuItem, {int quantity = 1, String? specialInstructions}) {
    if (_currentOrder == null) return;

    final uuid = Uuid();
    final now = DateTime.now();

    // Check if item already exists
    final existingIndex = _currentOrder!.items.indexWhere(
      (item) => item.menuItemId == menuItem.id &&
                item.instructionsSpeciales == specialInstructions,
    );

    if (existingIndex != -1) {
      // Update quantity
      final existing = _currentOrder!.items[existingIndex];
      _currentOrder!.items[existingIndex] = existing.copyWith(
        quantite: existing.quantite + quantity,
        prixTotal: (existing.quantite + quantity) * existing.prixUnitaire,
        updatedAt: now,
      );
    } else {
      // Add new item
      final orderItem = OrderItem(
        id: uuid.v4(),
        orderId: _currentOrder!.id,
        menuItemId: menuItem.id,
        menuItemName: menuItem.nom,
        quantite: quantity,
        prixUnitaire: menuItem.prix,
        prixTotal: menuItem.prix * quantity,
        instructionsSpeciales: specialInstructions,
        createdAt: now,
        updatedAt: now,
      );
      
      _currentOrder!.items.add(orderItem);
    }

    _recalculateTotal();
    notifyListeners();
  }

  void removeItem(String itemId) {
    if (_currentOrder == null) return;
    
    _currentOrder!.items.removeWhere((item) => item.id == itemId);
    _recalculateTotal();
    notifyListeners();
  }

  void updateItemQuantity(String itemId, int newQuantity) {
    if (_currentOrder == null) return;
    
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final index = _currentOrder!.items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _currentOrder!.items[index];
      _currentOrder!.items[index] = item.copyWith(
        quantite: newQuantity,
        prixTotal: item.prixUnitaire * newQuantity,
        updatedAt: DateTime.now(),
      );
      
      _recalculateTotal();
      notifyListeners();
    }
  }

  void _recalculateTotal() {
    if (_currentOrder == null) return;
    
    double subtotal = 0;
    for (var item in _currentOrder!.items) {
      subtotal += item.prixTotal;
    }

    _currentOrder = _currentOrder!.copyWith(
      subtotal: subtotal,
      totalAmount: subtotal,
      updatedAt: DateTime.now(),
    );
  }

  // ========== ORDER COMPLETION ==========
  
  Future<void> completeOrder({
    required String paymentMethod,
    bool printTicket = true,
    bool openDrawer = true,
  }) async {
    if (_currentOrder == null || _currentOrder!.items.isEmpty) {
      throw Exception('Commande vide');
    }

    try {
      _isProcessing = true;
      notifyListeners();

      // Update payment method
      _currentOrder = _currentOrder!.copyWith(
        paymentMethod: paymentMethod,
        updatedAt: DateTime.now(),
      );

      // Save to local database
      await _db.insertOrder(_currentOrder!);

      // Print ticket if requested
      if (printTicket) {
        try {
          await _printer.printOrder(_currentOrder!);
        } catch (e) {
          print('Print failed: $e');
          // Don't block order if print fails
        }
      }

      // Open cash drawer if requested
      if (openDrawer && paymentMethod == 'cash_on_delivery') {
        try {
          await _printer.openCashDrawer();
        } catch (e) {
          print('Cash drawer failed: $e');
        }
      }

      // Try to sync immediately if online
      _sync.syncOrdersToApi();

      // Reset for next order
      _startNewOrder();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void cancelOrder() {
    _startNewOrder();
    notifyListeners();
  }
}