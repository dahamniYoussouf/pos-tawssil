import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingMapState {
  final List<Marker> markers;
  final List<Polyline> polylines;
  final LatLngBounds? bounds;
  final LatLng center;

  const OrderTrackingMapState({
    required this.markers,
    required this.polylines,
    required this.center,
    this.bounds,
  });

  factory OrderTrackingMapState.initial() {
    return OrderTrackingMapState(
      markers: const <Marker>[],
      polylines: const <Polyline>[],
      bounds: null,
      center: const LatLng(36.7538, 3.0588),
    );
  }
}

class OrderTrackingMapCubit extends Cubit<OrderTrackingMapState> {
  OrderTrackingMapCubit() : super(OrderTrackingMapState.initial());
  void initDriver(DriverModel? driver) {
    if (driver != null) {
      _emitState(const <Marker>[], const <Polyline>[],
          LatLng(driver.latitude!, driver.longitude!), null);
    } else {
      _emitState(const <Marker>[], const <Polyline>[],
          const LatLng(36.7538, 3.0588), null);
    }
  }

  void updateOrder(OrderModel order) {
    final LatLng? restaurantLatLng = _getRestaurantLatLng(order);
    final LatLng? deliveryLatLng = _getDeliveryDestinationLatLng(order);
    final LatLng driverLatLng = _getDriverLatLng();
    if (restaurantLatLng == null && deliveryLatLng == null) {
      _emitState(const <Marker>[], const <Polyline>[], driverLatLng, null);
      return;
    }
    final List<LatLng> boundPoints =
        _collectBoundPoints(restaurantLatLng, deliveryLatLng, driverLatLng);
    final List<Marker> markers =
        _buildMarkers(order, restaurantLatLng, deliveryLatLng, driverLatLng);
    final List<Polyline> polylines =
        _buildPolylines(restaurantLatLng, deliveryLatLng);
    final LatLng center = restaurantLatLng ?? deliveryLatLng ?? driverLatLng;
    _emitState(markers, polylines, center, boundPoints);
  }

  void updateOrders(List<OrderModel> orders) {
    final LatLng driverLatLng = _getDriverLatLng();
    if (orders.isEmpty) {
      _emitState(const <Marker>[], const <Polyline>[], driverLatLng, null);
      return;
    }
    final List<LatLng> boundPoints = <LatLng>[];
    final List<Marker> markers = <Marker>[];
    final List<Polyline> polylines = <Polyline>[];
    for (final OrderModel order in orders) {
      final LatLng? restaurantLatLng = _getRestaurantLatLng(order);
      final LatLng? deliveryLatLng = _getDeliveryDestinationLatLng(order);
      if (restaurantLatLng == null && deliveryLatLng == null) {
        continue;
      }
      if (restaurantLatLng != null) {
        boundPoints.add(restaurantLatLng);
      }
      if (deliveryLatLng != null) {
        boundPoints.add(deliveryLatLng);
      }
      markers.addAll(
          _buildMarkers(order, restaurantLatLng, deliveryLatLng, driverLatLng));
      final List<Polyline> orderPolylines =
          _buildPolylines(restaurantLatLng, deliveryLatLng);
      polylines.addAll(orderPolylines);
    }
    boundPoints.add(driverLatLng);
    if (boundPoints.isEmpty) {
      _emitState(const <Marker>[], const <Polyline>[], driverLatLng, null);
      return;
    }
    _emitState(markers, polylines, boundPoints.first, boundPoints);
  }

  bool _isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude.isInfinite || longitude.isInfinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  LatLng? _getRestaurantLatLng(OrderModel order) {
    if (!_isValidCoordinate(
        order.restaurantLatitude, order.restaurantLongitude)) {
      return null;
    }
    return LatLng(order.restaurantLatitude!, order.restaurantLongitude!);
  }

  LatLng? _getDeliveryDestinationLatLng(OrderModel order) {
    if (!_isValidCoordinate(order.deliveryLatitude, order.deliveryLongitude)) {
      return null;
    }
    return LatLng(order.deliveryLatitude!, order.deliveryLongitude!);
  }

  LatLng _getDriverLatLng() {
    final DriverModel? driver = locator<DriverCubit>().driver;
    if (driver != null &&
        _isValidCoordinate(driver.latitude, driver.longitude)) {
      return LatLng(driver.latitude!, driver.longitude!);
    }
    return const LatLng(36.7538, 3.0588);
  }

  List<LatLng> _collectBoundPoints(
      LatLng? restaurantLatLng, LatLng? deliveryLatLng, LatLng driverLatLng) {
    final List<LatLng> boundPoints = <LatLng>[];
    if (restaurantLatLng != null) {
      boundPoints.add(restaurantLatLng);
    }
    if (deliveryLatLng != null) {
      boundPoints.add(deliveryLatLng);
    }
    boundPoints.add(driverLatLng);
    return boundPoints;
  }

  List<Marker> _buildMarkers(
    OrderModel order,
    LatLng? restaurantLatLng,
    LatLng? deliveryLatLng,
    LatLng driverLatLng,
  ) {
    final List<Marker> markers = <Marker>[];
    if (restaurantLatLng != null) {
      markers.add(_buildRestaurantMarker(
          restaurantLatLng, order.restaurantName ?? 'Restaurant'));
    }
    if (deliveryLatLng != null) {
      markers.add(_buildDeliveryDestinationMarker(
          deliveryLatLng, order.deliveryAddress ?? 'Destination'));
    }
    markers.add(_buildDriverMarker(driverLatLng));
    if (order.isDelivering && order.deliveryPerson != null) {
      final LatLng? courierLatLng = _getCourierLatLng(order.deliveryPerson!);
      if (courierLatLng != null) {
        markers.add(
            _buildCourierMarker(courierLatLng, order.deliveryPerson!.name));
      }
    }
    return markers;
  }

  LatLng? _getCourierLatLng(DeliveryPerson person) {
    if (!_isValidCoordinate(person.latitude, person.longitude)) {
      return null;
    }
    return LatLng(person.latitude!, person.longitude!);
  }

  Marker _buildRestaurantMarker(LatLng point, String name) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: name,
        child:
            const Icon(Icons.location_on, color: AppColors.redColor, size: 32),
      ),
    );
  }

  Marker _buildDeliveryDestinationMarker(LatLng point, String address) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: address,
        child: const Icon(Icons.location_on,
            color: AppColors.primaryColor, size: 32),
      ),
    );
  }

  Marker _buildDriverMarker(LatLng point) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: const Tooltip(
        message: 'My Location',
        child: Icon(Icons.my_location, color: AppColors.greenColor, size: 32),
      ),
    );
  }

  Marker _buildCourierMarker(LatLng point, String name) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: name,
        child: const Icon(Icons.delivery_dining,
            color: AppColors.blueAccentColor, size: 32),
      ),
    );
  }

  List<Polyline> _buildPolylines(
      LatLng? restaurantLatLng, LatLng? deliveryLatLng) {
    final List<Polyline> polylines = <Polyline>[];
    if (restaurantLatLng != null && deliveryLatLng != null) {
      polylines.add(
        Polyline(
          points: <LatLng>[restaurantLatLng, deliveryLatLng],
          color: AppColors.primaryColor,
          strokeWidth: 4,
        ),
      );
    }
    return polylines;
  }

  void _emitState(
    List<Marker> markers,
    List<Polyline> polylines,
    LatLng center,
    List<LatLng>? boundPointsList,
  ) {
    if (isClosed) return;
    if (!_isValidCoordinate(center.latitude, center.longitude)) {
      center = _getDriverLatLng();
    }
    final LatLngBounds? bounds =
        boundPointsList != null && boundPointsList.isNotEmpty
            ? LatLngBounds.fromPoints(boundPointsList)
            : null;
    emit(OrderTrackingMapState(
      markers: List<Marker>.unmodifiable(markers),
      polylines: List<Polyline>.unmodifiable(polylines),
      center: center,
      bounds: bounds,
    ));
  }
}
