import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/restaurant/models/menu_model.dart';
import '../states/cart_state.dart';

class CartItem {
  final MenuModel menuItem;
  final String menuItemId;
  final String menuItemName;
  final double price;
  final String imageUrl;
  int quantity;
  String? note;
  List<MenuItemOption> selectedOptions;

  CartItem({
    required this.menuItem,
    required this.menuItemId,
    required this.menuItemName,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.note,
    List<MenuItemOption>? selectedOptions,
  }) : selectedOptions = selectedOptions ?? [];

  double get totalPrice {
    double optionsTotal = 0.0;
    for (final option in selectedOptions) {
      optionsTotal += option.prix;
    }
    return (price + optionsTotal) * quantity;
  }
}

class CartCubit extends Cubit<CartState> {
  final Map<String, CartItem> _items = {};

  CartCubit() : super(CartInitial()) {
    _emitCurrentState();
  }

  Map<String, CartItem> get items => Map.unmodifiable(_items);

  int get totalItems {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  List<CartItem> getItemsForRestaurant({required String restaurantId}) {
    return _items.values
        .where((CartItem item) => item.menuItem.restaurantId == restaurantId)
        .toList(growable: false);
  }

  double getTotalPriceForRestaurant(String restaurantId) {
    return _items.values
        .where((item) => item.menuItem.restaurantId == restaurantId)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  void _emitCurrentState() {
    emit(CartUpdated(
      items: items,
      totalItems: totalItems,
      totalPrice: totalPrice,
      isEmpty: isEmpty,
    ));
  }

  void addOrSetItem({
    required MenuModel menuItem,
    required String menuItemId,
    required String menuItemName,
    required double price,
    required String imageUrl,
    required int quantity,
    String? note,
    List<MenuItemOption>? selectedOptions,
  }) {
    try {
      if (_items.containsKey(menuItemId)) {
        _items[menuItemId]!.quantity = quantity;
        if (note != null && note.isNotEmpty) {
          _items[menuItemId]!.note = note;
        }
        if (selectedOptions != null) {
          _items[menuItemId]!.selectedOptions = selectedOptions;
        }
      } else {
        _items[menuItemId] = CartItem(
          menuItem: menuItem,
          menuItemId: menuItemId,
          menuItemName: menuItemName,
          price: price,
          imageUrl: imageUrl,
          quantity: quantity,
          note: note,
          selectedOptions: selectedOptions,
        );
      }
      _emitCurrentState();
    } catch (e) {
      emit(CartError(
          message: 'Erreur lors de l\'ajout au panier: ${e.toString()}'));
    }
  }

  void removeItem(String menuItemId) {
    try {
      _items.remove(menuItemId);
      _emitCurrentState();
    } catch (e) {
      emit(
          CartError(message: 'Erreur lors de la suppression: ${e.toString()}'));
    }
  }

  void updateQuantity(String menuItemId, int quantity) {
    try {
      if (_items.containsKey(menuItemId)) {
        if (quantity <= 0) {
          _items.remove(menuItemId);
        } else {
          _items[menuItemId]!.quantity = quantity;
        }
        _emitCurrentState();
      }
    } catch (e) {
      emit(
          CartError(message: 'Erreur lors de la mise à jour: ${e.toString()}'));
    }
  }

  void updateNote(String menuItemId, String note) {
    try {
      if (_items.containsKey(menuItemId)) {
        _items[menuItemId]!.note = note;
        _emitCurrentState();
      }
    } catch (e) {
      emit(CartError(
          message:
              'Erreur lors de la mise à jour de la note: ${e.toString()}'));
    }
  }

  int getQuantity(String menuItemId) {
    return _items[menuItemId]?.quantity ?? 0;
  }

  bool hasItem(String menuItemId) {
    return _items.containsKey(menuItemId);
  }

  void clearCart() {
    _items.clear();
    _emitCurrentState();
  }

  CartItem? getItem(String menuItemId) {
    return _items[menuItemId];
  }

  void updateSelectedOptions(
    String menuItemId,
    List<MenuItemOption> selectedOptions,
  ) {
    try {
      if (_items.containsKey(menuItemId)) {
        _items[menuItemId]!.selectedOptions = selectedOptions;
        _emitCurrentState();
      }
    } catch (e) {
      emit(CartError(
          message:
              'Erreur lors de la mise à jour des options: ${e.toString()}'));
    }
  }
}
