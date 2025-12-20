import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:client_app/src/features/cart/states/cart_state.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:latlong2/latlong.dart' as latlong;

class NavigateToCartUseCase {
  final CartCubit _cartCubit;
  final LocationCubit _locationCubit;

  NavigateToCartUseCase({
    required CartCubit cartCubit,
    required LocationCubit locationCubit,
  })  : _cartCubit = cartCubit,
        _locationCubit = locationCubit;

  Future<NavigateToCartResult> execute(RestaurantModel restaurant) async {
    final cartState = _cartCubit.state;
    if (cartState is CartUpdated && cartState.isEmpty) {
      return NavigateToCartResult.emptyCart();
    }
    await _locationCubit.loadSavedLocation();
    final locationState = _locationCubit.state;
    if (locationState is LocationSuccess) {
      final deliveryAddress = locationState.fullAddress;
      final latitude = locationState.latitude ?? 0.0;
      final longitude = locationState.longitude ?? 0.0;
      final deliveryLocation = latlong.LatLng(latitude, longitude);
      final restaurantLocation =
          latlong.LatLng(restaurant.lat ?? 0.0, restaurant.lng ?? 0.0);
      return NavigateToCartResult.success(
        restaurantName: restaurant.name,
        restaurantId: restaurant.id,
        deliveryAddress: deliveryAddress,
        restaurantLocation: restaurantLocation,
        deliveryLocation: deliveryLocation,
      );
    }
    return NavigateToCartResult.error();
  }
}

class NavigateToCartResult {
  final bool isSuccess;
  final bool isEmptyCart;
  final String? restaurantName;
  final String? restaurantId;
  final String? deliveryAddress;
  final latlong.LatLng? restaurantLocation;
  final latlong.LatLng? deliveryLocation;

  NavigateToCartResult({
    required this.isSuccess,
    required this.isEmptyCart,
    this.restaurantName,
    this.restaurantId,
    this.deliveryAddress,
    this.restaurantLocation,
    this.deliveryLocation,
  });

  factory NavigateToCartResult.emptyCart() {
    return NavigateToCartResult(
      isSuccess: false,
      isEmptyCart: true,
    );
  }

  factory NavigateToCartResult.success({
    required String restaurantName,
    required String restaurantId,
    required String deliveryAddress,
    required latlong.LatLng restaurantLocation,
    required latlong.LatLng deliveryLocation,
  }) {
    return NavigateToCartResult(
      isSuccess: true,
      isEmptyCart: false,
      restaurantName: restaurantName,
      restaurantId: restaurantId,
      deliveryAddress: deliveryAddress,
      restaurantLocation: restaurantLocation,
      deliveryLocation: deliveryLocation,
    );
  }

  factory NavigateToCartResult.error() {
    return NavigateToCartResult(
      isSuccess: false,
      isEmptyCart: false,
    );
  }
}

