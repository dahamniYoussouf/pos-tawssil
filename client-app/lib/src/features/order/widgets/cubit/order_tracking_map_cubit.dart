import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
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

  factory OrderTrackingMapState.initial(LatLng fallbackCenter) {
    return OrderTrackingMapState(
      markers: const <Marker>[],
      polylines: const <Polyline>[],
      center: fallbackCenter,
      bounds: null,
    );
  }
}

class OrderTrackingMapCubit extends Cubit<OrderTrackingMapState> {
  static const LatLng _defaultFallbackCenter = LatLng(36.7538, 3.0588);

  final LatLng _fallbackCenter;

  OrderTrackingMapCubit({LatLng? fallbackCenter})
      : _fallbackCenter = fallbackCenter ?? _defaultFallbackCenter,
        super(OrderTrackingMapState.initial(fallbackCenter ?? _defaultFallbackCenter));

  void updateOrder(OrderModel order) {
    if (isClosed) return;

    if (!_hasRequiredCoordinates(order)) {
      emit(OrderTrackingMapState(
        markers: const <Marker>[],
        polylines: const <Polyline>[],
        center: _fallbackCenter,
        bounds: null,
      ));
      return;
    }

    final LatLng restaurantLatLng = _createRestaurantLatLng(order);
    final LatLng deliveryLatLng = _createDeliveryLatLng(order);
    final List<LatLng> boundPoints = <LatLng>[restaurantLatLng, deliveryLatLng];
    final List<Marker> markers = _buildMarkers(order, restaurantLatLng, deliveryLatLng, boundPoints);
    final List<Polyline> polylines = <Polyline>[_buildRoutePolyline(restaurantLatLng, deliveryLatLng)];

    if (isClosed) return;

    emit(OrderTrackingMapState(
      markers: List<Marker>.unmodifiable(markers),
      polylines: List<Polyline>.unmodifiable(polylines),
      center: restaurantLatLng,
      bounds: LatLngBounds.fromPoints(boundPoints),
    ));
  }

  bool _hasRequiredCoordinates(OrderModel order) {
    return order.restaurantLatitude != null && order.restaurantLongitude != null && order.deliveryLatitude != null && order.deliveryLongitude != null;
  }

  LatLng _createRestaurantLatLng(OrderModel order) {
    return LatLng(order.restaurantLatitude!, order.restaurantLongitude!);
  }

  LatLng _createDeliveryLatLng(OrderModel order) {
    return LatLng(order.deliveryLatitude!, order.deliveryLongitude!);
  }

  List<Marker> _buildMarkers(OrderModel order, LatLng restaurantLatLng, LatLng deliveryLatLng, List<LatLng> boundPoints) {
    final List<Marker> markers = <Marker>[
      Marker(
        point: restaurantLatLng,
        width: 44,
        height: 44,
        child: Tooltip(
          message: order.restaurantName ?? 'Restaurant',
          child: const Icon(Icons.location_on, color: ColorApp.redColor, size: 32),
        ),
      ),
      Marker(
        point: deliveryLatLng,
        width: 44,
        height: 44,
        child: Tooltip(
          message: order.deliveryAddress ?? 'Destination',
          child: const Icon(Icons.location_on, color: ColorApp.primary, size: 32),
        ),
      ),
    ];

    if (order.isDelivering && order.deliveryPerson != null) {
      final DeliveryPerson person = order.deliveryPerson!;
      if (person.latitude != null && person.longitude != null) {
        final LatLng courierPoint = LatLng(person.latitude!, person.longitude!);
        boundPoints.add(courierPoint);
        markers.add(
          Marker(
            point: courierPoint,
            width: 44,
            height: 44,
            child: Tooltip(
              message: person.name,
              child: const Icon(Icons.delivery_dining, color: ColorApp.blueAccentColor, size: 32),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Polyline _buildRoutePolyline(LatLng restaurantLatLng, LatLng deliveryLatLng) {
    return Polyline(
      points: <LatLng>[restaurantLatLng, deliveryLatLng],
      color: ColorApp.primary,
      strokeWidth: 4,
    );
  }
}
