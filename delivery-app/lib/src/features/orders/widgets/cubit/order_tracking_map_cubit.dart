import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_app/src/core/res/color_app.dart';

class OrderTrackingMapState {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLngBounds? bounds;
  final LatLng center;

  const OrderTrackingMapState({
    required this.markers,
    required this.polylines,
    required this.center,
    this.bounds,
  });

  factory OrderTrackingMapState.initial() {
    return const OrderTrackingMapState(
      markers: <Marker>{},
      polylines: <Polyline>{},
      bounds: null,
      center: LatLng(36.7538, 3.0588),
    );
  }
}

class OrderTrackingMapCubit extends Cubit<OrderTrackingMapState> {
  OrderTrackingMapCubit() : super(OrderTrackingMapState.initial());

  void initDriver(DriverModel? driver) {
    if (driver != null &&
        _isValidCoordinate(driver.latitude, driver.longitude)) {
      _emitState(<Marker>{}, <Polyline>{},
          LatLng(driver.latitude!, driver.longitude!), null);
    } else {
      _emitState(<Marker>{}, <Polyline>{}, const LatLng(36.7538, 3.0588), null);
    }
  }

  void updateOrder(OrderModel order) {
    final LatLng? restaurantLatLng = _getRestaurantLatLng(order);
    final LatLng? deliveryLatLng = _getDeliveryDestinationLatLng(order);
    final LatLng driverLatLng = _getDriverLatLng();
    if (restaurantLatLng == null && deliveryLatLng == null) {
      _emitState(<Marker>{}, <Polyline>{}, driverLatLng, null);
      return;
    }
    final List<LatLng> boundPoints =
        _collectBoundPoints(restaurantLatLng, deliveryLatLng, driverLatLng);
    final Set<Marker> markers =
        _buildMarkers(order, restaurantLatLng, deliveryLatLng, driverLatLng);
    final Set<Polyline> polylines =
        _buildPolylines(restaurantLatLng, deliveryLatLng);
    final LatLng center = restaurantLatLng ?? deliveryLatLng ?? driverLatLng;
    _emitState(markers, polylines, center, boundPoints);
  }

  void updateOrders(List<OrderModel> orders) {
    final LatLng driverLatLng = _getDriverLatLng();
    if (orders.isEmpty) {
      _emitState(<Marker>{}, <Polyline>{}, driverLatLng, null);
      return;
    }
    final List<LatLng> boundPoints = <LatLng>[];
    final Set<Marker> markers = <Marker>{};
    final Set<Polyline> polylines = <Polyline>{};
    for (int i = 0; i < orders.length; i++) {
      final OrderModel order = orders[i];
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
      polylines.addAll(_buildPolylines(restaurantLatLng, deliveryLatLng));
    }
    boundPoints.add(driverLatLng);
    if (boundPoints.isEmpty) {
      _emitState(<Marker>{}, <Polyline>{}, driverLatLng, null);
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

  Set<Marker> _buildMarkers(
    OrderModel order,
    LatLng? restaurantLatLng,
    LatLng? deliveryLatLng,
    LatLng driverLatLng,
  ) {
    final Set<Marker> markers = <Marker>{};
    if (restaurantLatLng != null) {
      markers.add(_buildRestaurantMarker(
          restaurantLatLng, order.restaurantName ?? 'Restaurant', order.id));
    }
    if (deliveryLatLng != null) {
      markers.add(_buildDeliveryDestinationMarker(
          deliveryLatLng, order.deliveryAddress ?? 'Destination', order.id));
    }
    markers.add(_buildDriverMarker(driverLatLng));
    if (order.isDelivering && order.deliveryPerson != null) {
      final LatLng? courierLatLng = _getCourierLatLng(order.deliveryPerson!);
      if (courierLatLng != null) {
        markers.add(_buildCourierMarker(
            courierLatLng, order.deliveryPerson!.name, order.id));
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

  Marker _buildRestaurantMarker(LatLng point, String name, String orderId) {
    return Marker(
      markerId: MarkerId('restaurant_$orderId'),
      position: point,
      infoWindow: InfoWindow(title: name),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }

  Marker _buildDeliveryDestinationMarker(
      LatLng point, String address, String orderId) {
    return Marker(
      markerId: MarkerId('delivery_$orderId'),
      position: point,
      infoWindow: InfoWindow(title: address),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
  }

  Marker _buildDriverMarker(LatLng point) {
    return Marker(
      markerId: const MarkerId('driver'),
      position: point,
      infoWindow: const InfoWindow(title: 'My Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  Marker _buildCourierMarker(LatLng point, String name, String orderId) {
    return Marker(
      markerId: MarkerId('courier_$orderId'),
      position: point,
      infoWindow: InfoWindow(title: name),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  Set<Polyline> _buildPolylines(
      LatLng? restaurantLatLng, LatLng? deliveryLatLng) {
    final Set<Polyline> polylines = <Polyline>{};
    if (restaurantLatLng != null && deliveryLatLng != null) {
      polylines.add(
        Polyline(
          polylineId: PolylineId(
              '${restaurantLatLng.latitude}_${deliveryLatLng.latitude}'),
          points: <LatLng>[restaurantLatLng, deliveryLatLng],
          color: AppColors.primaryColor,
          width: 4,
        ),
      );
    }
    return polylines;
  }

  void _emitState(
    Set<Marker> markers,
    Set<Polyline> polylines,
    LatLng center,
    List<LatLng>? boundPointsList,
  ) {
    if (isClosed) return;
    if (!_isValidCoordinate(center.latitude, center.longitude)) {
      center = _getDriverLatLng();
    }
    LatLngBounds? bounds;
    if (boundPointsList != null && boundPointsList.length >= 2) {
      double minLat = boundPointsList.first.latitude;
      double maxLat = boundPointsList.first.latitude;
      double minLng = boundPointsList.first.longitude;
      double maxLng = boundPointsList.first.longitude;
      for (final LatLng point in boundPointsList) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }
    emit(OrderTrackingMapState(
      markers: Set<Marker>.from(markers),
      polylines: Set<Polyline>.from(polylines),
      center: center,
      bounds: bounds,
    ));
  }
}
