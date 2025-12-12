// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/menu_item.dart';
import '../models/order_item_addition.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/print_service.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync;
  final PrintService _printer = PrintService();

  Order? _currentOrder;
  String? _selectedCashierId;
  String? _restaurantId;
  bool _isProcessing = false;

  Order? get currentOrder => _currentOrder;
  String? get selectedCashierId => _selectedCashierId;
  bool get isProcessing => _isProcessing;
  
  double get total {
    final sum = _currentOrder?.totalAmount ?? 0.0;
    print('💰 total: $sum DA');
    return sum;
  }
  
  int get itemCount {
    final count = _currentOrder?.items.length ?? 0;
    print('📊 itemCount: $count');
    return count;
  }

  OrderProvider({required SyncService syncService}) : _sync = syncService;

  // ========== INITIALIZATION ==========
  
  Future<void> _loadCashierInfo() async {
    if (_selectedCashierId != null && _restaurantId != null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCashierId = prefs.getString('cashier_id');
      _restaurantId = prefs.getString('restaurant_id');
      
      print('👤 Loaded Cashier ID: $_selectedCashierId');
      print('🏪 Loaded Restaurant ID: $_restaurantId');
    } catch (e) {
      print('⚠️ Error loading cashier info: $e');
    }
  }

  // ========== CASHIER SELECTION ==========
  
  void selectCashier(String cashierId) {
    print('👤 Selecting cashier: $cashierId');
    _selectedCashierId = cashierId;
    _startNewOrder();
    notifyListeners();
  }

  Future<void> _startNewOrder() async {
    await _loadCashierInfo();
    
    final uuid = Uuid();
    final now = DateTime.now();
    final orderNumber = 'POS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';

    print('🆕 Creating new order: $orderNumber');

    _currentOrder = Order(
      id: uuid.v4(),
      orderNumber: orderNumber,
      cashierId: _selectedCashierId ?? 'default-cashier',
      restaurantId: _restaurantId ?? '',
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
    
    print('✅ Order created with ID: ${_currentOrder!.id}');
  }

  // ========== ORDER MANAGEMENT ==========
  
  void addItem(MenuItem menuItem, {int quantity = 1, String? specialInstructions, List<OrderItemAddition> additions = const []}) async {
    print('🔵 addItem called: ${menuItem.nom}');
    
    // ✅ Si pas de commande en cours, en créer une automatiquement
    if (_currentOrder == null) {
      print('🆕 No current order, creating one automatically');
      await _startNewOrder();
    }

    final uuid = Uuid();
    final now = DateTime.now();

    // Check if item already exists with the same additions and instructions
    final additionKey = additions.map((a) => '${a.additionId}:${a.quantity}').toList()..sort();
    final existingIndex = _currentOrder!.items.indexWhere((item) {
      final itemKey = item.additions.map((a) => '${a.additionId}:${a.quantity}').toList()..sort();
      return item.menuItemId == menuItem.id &&
          item.instructionsSpeciales == specialInstructions &&
          listEquals(itemKey, additionKey);
    });

    final additionsPerUnit = additions.fold<double>(
      0,
      (double sum, OrderItemAddition add) => sum + (add.prix * add.quantity),
    );

    if (existingIndex != -1) {
      // Update quantity
      print('➕ Incrementing quantity for existing item');
      final existing = _currentOrder!.items[existingIndex];
      _currentOrder!.items[existingIndex] = existing.copyWith(
        quantite: existing.quantite + quantity,
        prixTotal: ((existing.quantite + quantity) * existing.prixUnitaire) +
            additionsPerUnit * (existing.quantite + quantity),
        additionsTotal: additionsPerUnit * (existing.quantite + quantity),
        updatedAt: now,
      );
    } else {
      // Add new item
      print('✨ Adding new item to order');
      final orderItem = OrderItem(
        id: uuid.v4(),
        orderId: _currentOrder!.id,
        menuItemId: menuItem.id,
        menuItemName: menuItem.nom,
        quantite: quantity,
        prixUnitaire: menuItem.prix,
        prixTotal: (menuItem.prix * quantity) + (additionsPerUnit * quantity),
        additionsTotal: additionsPerUnit * quantity,
        additions: additions,
        instructionsSpeciales: specialInstructions,
        createdAt: now,
        updatedAt: now,
      );
      
      _currentOrder!.items.add(orderItem);
    }

    print('✅ Order now has ${_currentOrder!.items.length} items');
    _recalculateTotal();
    notifyListeners();
    print('🔔 notifyListeners called');
  }

  void removeItem(String itemId) {
    print('🔵 removeItem: $itemId');
    if (_currentOrder == null) return;
    
    _currentOrder!.items.removeWhere((item) => item.id == itemId);
    _recalculateTotal();
    notifyListeners();
    print('🔔 notifyListeners called');
  }

  void updateItemQuantity(String itemId, int newQuantity) {
    print('🔵 updateItemQuantity: $itemId -> $newQuantity');
    if (_currentOrder == null) return;
    
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final index = _currentOrder!.items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _currentOrder!.items[index];
      final additionsPerUnit = item.additions.fold<double>(
        0,
        (double sum, OrderItemAddition add) => sum + (add.prix * add.quantity),
      );
      _currentOrder!.items[index] = item.copyWith(
        quantite: newQuantity,
        prixTotal: (item.prixUnitaire * newQuantity) + (additionsPerUnit * newQuantity),
        additionsTotal: additionsPerUnit * newQuantity,
        updatedAt: DateTime.now(),
      );
      
      _recalculateTotal();
      notifyListeners();
      print('🔔 notifyListeners called');
    }
  }

  void _recalculateTotal() {
    if (_currentOrder == null) return;
    
    double subtotal = 0;
    for (var item in _currentOrder!.items) {
      final additionsSum = item.additions.fold<double>(
        0,
        (double sum, OrderItemAddition add) => sum + add.total,
      );
      subtotal += (item.prixUnitaire * item.quantite) + additionsSum;
    }

    print('Recalculating total: $subtotal DA');

    _currentOrder = _currentOrder!.copyWith(
      subtotal: subtotal,
      totalAmount: subtotal,
      updatedAt: DateTime.now(),
    );
  }

  // ========== ORDER COMPLETION ==========
  
  void setOrderType(String orderType) {
    if (_currentOrder == null) return;
    _currentOrder = _currentOrder!.copyWith(orderType: orderType);
    notifyListeners();
  }
  
  Future<void> completeOrder({
    required String paymentMethod,
    bool printTicket = true,
    bool openDrawer = true,
  }) async {
    print('🔵 completeOrder called');
    
    if (_currentOrder == null || _currentOrder!.items.isEmpty) {
      print('⚠️ No order to complete');
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

      print('💾 Saving order to database...');
      
      // Save to local database
      await _db.insertOrder(_currentOrder!);

      print('✅ Order saved successfully');

      // Print ticket if requested
      if (printTicket) {
        try {
          print('🖨️ Printing ticket...');
          await _printer.printOrder(_currentOrder!);
        } catch (e) {
          print('❌ Print failed: $e');
          // Don't block order if print fails
        }
      }

      // Open cash drawer if requested
      if (openDrawer && paymentMethod == 'cash_on_delivery') {
        try {
          print('💵 Opening cash drawer...');
          await _printer.openCashDrawer();
        } catch (e) {
          print('❌ Cash drawer failed: $e');
        }
      }

      // Try to sync immediately if online
      print('🔄 Syncing to API...');
      _sync.syncOrdersToApi();

      // Reset for next order
      await _startNewOrder();
      print('🔔 Order completed and reset');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void cancelOrder() async {
    print('🔵 cancelOrder called');
    await _startNewOrder();
    notifyListeners();
    print('🔔 notifyListeners called');
  }
}
