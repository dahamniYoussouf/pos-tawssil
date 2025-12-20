import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/cart_service.dart';
import '../states/cart_state.dart';

// Cart Cubit
class CartCubit extends Cubit<CartState> {
  final CartService _cartService;

  CartCubit({CartService? cartService})
      : _cartService = cartService ?? CartService(),
        super(CartInitial()) {
    _cartService.addListener(_onCartChanged);
    _emitCurrentState();
  }

  void _onCartChanged() {
    _emitCurrentState();
  }

  void _emitCurrentState() {
    emit(CartUpdated(
      items: _cartService.items,
      totalItems: _cartService.totalItems,
      totalPrice: _cartService.totalPrice,
      isEmpty: _cartService.isEmpty,
    ));
  }

  void addItem({
    required String menuItemId,
    required String menuItemName,
    required double price,
    required String imageUrl,
    int quantity = 1,
    String? note,
  }) {
    try {
      _cartService.addItem(
        menuItemId: menuItemId,
        menuItemName: menuItemName,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
        note: note,
      );
    } catch (e) {
      emit(CartError(
          message: 'Erreur lors de l\'ajout au panier: ${e.toString()}'));
    }
  }

  void addOrSetItem({
    required String menuItemId,
    required String menuItemName,
    required double price,
    required String imageUrl,
    required int quantity,
    String? note,
  }) {
    try {
      if (_cartService.hasItem(menuItemId)) {
        _cartService.updateQuantity(menuItemId, quantity);
        if (note != null && note.isNotEmpty) {
          _cartService.updateNote(menuItemId, note);
        }
      } else {
        _cartService.addItem(
          menuItemId: menuItemId,
          menuItemName: menuItemName,
          price: price,
          imageUrl: imageUrl,
          quantity: quantity,
          note: note,
        );
      }
    } catch (e) {
      emit(CartError(
          message: 'Erreur lors de l\'ajout au panier: ${e.toString()}'));
    }
  }

  void removeItem(String menuItemId) {
    try {
      _cartService.removeItem(menuItemId);
    } catch (e) {
      emit(
          CartError(message: 'Erreur lors de la suppression: ${e.toString()}'));
    }
  }

  void updateQuantity(String menuItemId, int quantity) {
    try {
      _cartService.updateQuantity(menuItemId, quantity);
    } catch (e) {
      emit(
          CartError(message: 'Erreur lors de la mise à jour: ${e.toString()}'));
    }
  }

  void updateNote(String menuItemId, String note) {
    try {
      _cartService.updateNote(menuItemId, note);
    } catch (e) {
      emit(CartError(
          message:
              'Erreur lors de la mise à jour de la note: ${e.toString()}'));
    }
  }

  CartItem? getItem(String menuItemId) {
    return _cartService.getItem(menuItemId);
  }

  @override
  Future<void> close() {
    _cartService.removeListener(_onCartChanged);
    return super.close();
  }
}
