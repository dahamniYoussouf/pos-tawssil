import 'package:client_app/src/features/cart/states/cart_state.dart';

class CartData {
  final int totalItems;
  final double totalPrice;
  final bool isEmpty;
  final Map<String, int> quantities;

  const CartData({
    required this.totalItems,
    required this.totalPrice,
    required this.isEmpty,
    required this.quantities,
  });
}

class CartDataExtractor {
  static CartData extract(CartState cartState) {
    if (cartState is CartUpdated) {
      final quantities = <String, int>{};
      for (var item in cartState.items.values) {
        quantities[item.menuItemId] = item.quantity;
      }
      return CartData(
        totalItems: cartState.totalItems,
        totalPrice: cartState.totalPrice,
        isEmpty: cartState.isEmpty,
        quantities: quantities,
      );
    }
    return const CartData(
      totalItems: 0,
      totalPrice: 0.0,
      isEmpty: true,
      quantities: {},
    );
  }
}

