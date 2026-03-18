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

  double get totalBeforePromotions => _sumOrder(usePromo: false);

  double get totalAfterPromotions => _sumOrder(usePromo: true);
  
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
    final promoUnitPrice = menuItem.promotionalPrice;
    final effectiveUnitPrice = promoUnitPrice ?? menuItem.prix;

    if (existingIndex != -1) {
      // Update quantity
      print('➕ Incrementing quantity for existing item');
      final existing = _currentOrder!.items[existingIndex];
      _currentOrder!.items[existingIndex] = existing.copyWith(
        quantite: existing.quantite + quantity,
        prixTotal: ((existing.quantite + quantity) * (existing.promotionalPrice ?? promoUnitPrice ?? existing.prixUnitaire)) +
            additionsPerUnit * (existing.quantite + quantity),
        additionsTotal: additionsPerUnit * (existing.quantite + quantity),
        promotionalPrice: existing.promotionalPrice ?? promoUnitPrice,
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
        photoUrl: menuItem.photoUrl,
        quantite: quantity,
        prixUnitaire: menuItem.prix,
        prixTotal: (effectiveUnitPrice * quantity) + (additionsPerUnit * quantity),
        promotionalPrice: promoUnitPrice,
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
      final effectiveUnit = item.promotionalPrice ?? item.prixUnitaire;
      _currentOrder!.items[index] = item.copyWith(
        quantite: newQuantity,
        prixTotal: (effectiveUnit * newQuantity) + (additionsPerUnit * newQuantity),
        additionsTotal: additionsPerUnit * newQuantity,
        updatedAt: DateTime.now(),
      );
      
      _recalculateTotal();
      notifyListeners();
      print('🔔 notifyListeners called');
    }
  }

  void updateItemConfiguration(
    String itemId,
    MenuItem menuItem, {
    required int quantity,
    String? specialInstructions,
    List<OrderItemAddition> additions = const [],
  }) {
    print('updateItemConfiguration: $itemId -> ${menuItem.nom}');
    if (_currentOrder == null) return;

    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final itemIndex =
        _currentOrder!.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final now = DateTime.now();
    final additionsPerUnit = additions.fold<double>(
      0,
      (double sum, OrderItemAddition add) => sum + (add.prix * add.quantity),
    );
    final promoUnitPrice = menuItem.promotionalPrice;
    final effectiveUnitPrice = promoUnitPrice ?? menuItem.prix;
    final additionKey =
        additions.map((a) => '${a.additionId}:${a.quantity}').toList()..sort();

    final mergeIndex = _currentOrder!.items.indexWhere((item) {
      if (item.id == itemId) return false;
      final itemKey =
          item.additions.map((a) => '${a.additionId}:${a.quantity}').toList()
            ..sort();
      return item.menuItemId == menuItem.id &&
          item.instructionsSpeciales == specialInstructions &&
          listEquals(itemKey, additionKey);
    });

    if (mergeIndex != -1) {
      final existing = _currentOrder!.items[mergeIndex];
      final mergedQuantity = existing.quantite + quantity;
      _currentOrder!.items[mergeIndex] = existing.copyWith(
        menuItemName: menuItem.nom,
        photoUrl: menuItem.photoUrl,
        quantite: mergedQuantity,
        prixUnitaire: menuItem.prix,
        prixTotal: (effectiveUnitPrice * mergedQuantity) +
            (additionsPerUnit * mergedQuantity),
        additionsTotal: additionsPerUnit * mergedQuantity,
        additions: additions,
        promotionalPrice: promoUnitPrice,
        instructionsSpeciales: specialInstructions,
        updatedAt: now,
      );
      _currentOrder!.items.removeWhere((item) => item.id == itemId);
    } else {
      final current = _currentOrder!.items[itemIndex];
      _currentOrder!.items[itemIndex] = current.copyWith(
        menuItemName: menuItem.nom,
        photoUrl: menuItem.photoUrl,
        quantite: quantity,
        prixUnitaire: menuItem.prix,
        prixTotal:
            (effectiveUnitPrice * quantity) + (additionsPerUnit * quantity),
        additionsTotal: additionsPerUnit * quantity,
        additions: additions,
        promotionalPrice: promoUnitPrice,
        instructionsSpeciales: specialInstructions,
        updatedAt: now,
      );
    }

    _recalculateTotal();
    notifyListeners();
    print('notifyListeners called');
  }

  void _recalculateTotal() {
    if (_currentOrder == null) return;
    
    final before = _sumOrder(usePromo: false);
    final after = _sumOrder(usePromo: true);

    print('Recalculating totals: $before -> $after DA');

    _currentOrder = _currentOrder!.copyWith(
      subtotal: before,
      totalAmount: after,
      updatedAt: DateTime.now(),
    );
  }

  double _sumOrder({required bool usePromo}) {
    if (_currentOrder == null) return 0.0;
    return _currentOrder!.items.fold(0.0, (prev, item) {
      final additionSum = item.additionsTotal;
      final unitPrice = usePromo ? (item.promotionalPrice ?? item.prixUnitaire) : item.prixUnitaire;
      return prev + (unitPrice * item.quantite) + additionSum;
    });
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

      // Print ticket if requested (asynchronously, doesn't block)
      if (printTicket) {
        try {
          print('🖨️ Queuing print jobs...');
          // Utiliser printOrderAsync pour ne pas bloquer l'UI
          _printer.printOrderAsync(
            _currentOrder!,
            onError: (error) {
              print('❌ Print error: $error');
              // L'erreur sera gérée par le Stream de statut
            },
          );
        } catch (e) {
          print('❌ Print queue failed: $e');
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
