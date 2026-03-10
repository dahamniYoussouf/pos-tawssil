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
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync;
  final PrintService _printer = PrintService();
  final ApiService _api = ApiService();

  Order? _currentOrder;
  String? _selectedCashierId;
  String? _restaurantId;
  bool _isProcessing = false;

  Order? get currentOrder => _currentOrder;
  String? get selectedCashierId => _selectedCashierId;
  bool get isProcessing => _isProcessing;
  
  double get total {
    final sum = _currentOrder?.totalAmount ?? 0.0;
    return sum;
  }

  double get totalBeforePromotions => _sumOrder(usePromo: false);

  double get totalAfterPromotions => _sumOrder(usePromo: true);
  
  int get itemCount {
    final count = _currentOrder?.items.length ?? 0;
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
      
    } catch (e) {
    }
  }

  // ========== CASHIER SELECTION ==========
  
  void selectCashier(String cashierId) {
    _selectedCashierId = cashierId;
    _startNewOrder();
    notifyListeners();
  }

  Future<void> _startNewOrder() async {
    await _loadCashierInfo();
    
    final uuid = Uuid();
    final now = DateTime.now();
    final orderNumber = 'POS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';


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
    
  }

  // ========== ORDER MANAGEMENT ==========
  
  void addItem(MenuItem menuItem, {int quantity = 1, String? specialInstructions, List<OrderItemAddition> additions = const []}) async {
    
    // ✅ Si pas de commande en cours, en créer une automatiquement
    if (_currentOrder == null) {
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
    }
  }

  void _recalculateTotal() {
    if (_currentOrder == null) return;
    
    final before = _sumOrder(usePromo: false);
    final after = _sumOrder(usePromo: true);


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
    // Eviter les doubles validations (double clic, multi-tap)
    if (_isProcessing) {
      return;
    }
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


      // Si en ligne, synchroniser immédiatement pour récupérer le numéro PKP
      // afin d'imprimer un seul ticket avec l'ordre serveur.
      bool syncedNow = false;
      try {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity != ConnectivityResult.none) {
          final serverOrder = await _api.createOrder(_currentOrder!);
          final serverId = serverOrder['id']?.toString();
          final serverNumber = serverOrder['order_number']?.toString();
          if (serverId != null && serverId.isNotEmpty && serverNumber != null && serverNumber.isNotEmpty) {
            await _db.markOrderAsSyncedWithServer(
              localOrderId: _currentOrder!.id,
              serverOrderId: serverId,
              serverOrderNumber: serverNumber,
            );
            _currentOrder = _currentOrder!.copyWith(
              id: serverId,
              orderNumber: serverNumber,
              synced: true,
            );
            syncedNow = true;
          }
        }
      } catch (e) {
      }

      // Print ticket if requested (asynchronously, doesn't block)
      if (printTicket) {
        try {
          // Utiliser printOrderAsync pour ne pas bloquer l'UI
          _printer.printOrderAsync(
            _currentOrder!,
            onError: (error) {
              // L'erreur sera gérée par le Stream de statut
            },
          );
        } catch (e) {
          // Don't block order if print fails
        }
      }

      // Open cash drawer if requested
      if (openDrawer && paymentMethod == 'cash_on_delivery') {
        try {
          await _printer.openCashDrawer();
        } catch (e) {
        }
      }

      // Try to sync immediately if online
      if (!syncedNow) {
        _sync.syncOrdersToApi();
      }

      // Reset for next order
      await _startNewOrder();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void cancelOrder() async {
    await _startNewOrder();
    notifyListeners();
  }
}


