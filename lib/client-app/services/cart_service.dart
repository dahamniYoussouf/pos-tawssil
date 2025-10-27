import 'package:flutter/foundation.dart';

class CartItem {
  final String menuItemId;
  final String menuItemName;
  final double price;
  final String imageUrl;
  int quantity;
  String? note;

  CartItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.note,
  });

  double get totalPrice => price * quantity;
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => Map.unmodifiable(_items);

  int get totalItems {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  void addItem({
    required String menuItemId,
    required String menuItemName,
    required double price,
    required String imageUrl,
    int quantity = 1,
    String? note,
  }) {
    if (_items.containsKey(menuItemId)) {
      _items[menuItemId]!.quantity += quantity;
      if (note != null && note.isNotEmpty) {
        _items[menuItemId]!.note = note;
      }
    } else {
      _items[menuItemId] = CartItem(
        menuItemId: menuItemId,
        menuItemName: menuItemName,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
        note: note,
      );
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (_items.containsKey(menuItemId)) {
      if (quantity <= 0) {
        _items.remove(menuItemId);
      } else {
        _items[menuItemId]!.quantity = quantity;
      }
      notifyListeners();
    }
  }

  void updateNote(String menuItemId, String note) {
    if (_items.containsKey(menuItemId)) {
      _items[menuItemId]!.note = note;
      notifyListeners();
    }
  }

  int getQuantity(String menuItemId) {
    return _items[menuItemId]?.quantity ?? 0;
  }

  bool hasItem(String menuItemId) {
    return _items.containsKey(menuItemId);
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void clearCart() {
    clear();
  }

  CartItem? getItem(String menuItemId) {
    return _items[menuItemId];
  }
}
