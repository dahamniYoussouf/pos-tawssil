import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      bounds: _createBounds(boundPoints),
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
        markerId: const MarkerId('restaurant'),
        position: restaurantLatLng,
        infoWindow: InfoWindow(title: order.restaurantName ?? 'Restaurant'),
        icon: _createMarkerIcon(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: deliveryLatLng,
        infoWindow: InfoWindow(title: order.deliveryAddress ?? 'Destination'),
        icon: _createMarkerIcon(BitmapDescriptor.hueAzure),
      ),
    ];

    if (order.isDelivering && order.deliveryPerson != null) {
      final DeliveryPerson person = order.deliveryPerson!;
      if (person.latitude != null && person.longitude != null) {
        final LatLng courierPoint = LatLng(person.latitude!, person.longitude!);
        boundPoints.add(courierPoint);
        markers.add(
          Marker(
            markerId: const MarkerId('courier'),
            position: courierPoint,
            infoWindow: InfoWindow(title: person.name),
            icon: _createMarkerIcon(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }

    return markers;
  }

  Polyline _buildRoutePolyline(LatLng restaurantLatLng, LatLng deliveryLatLng) {
    return Polyline(
      polylineId: const PolylineId('route'),
      points: <LatLng>[restaurantLatLng, deliveryLatLng],
      color: ColorApp.primary,
      width: 4,
    );
  }

  BitmapDescriptor _createMarkerIcon(double hue) {
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  LatLngBounds _createBounds(List<LatLng> points) {
    double minLatitude = points.first.latitude;
    double maxLatitude = points.first.latitude;
    double minLongitude = points.first.longitude;
    double maxLongitude = points.first.longitude;
    for (final LatLng point in points) {
      minLatitude = point.latitude < minLatitude ? point.latitude : minLatitude;
      maxLatitude = point.latitude > maxLatitude ? point.latitude : maxLatitude;
      minLongitude = point.longitude < minLongitude ? point.longitude : minLongitude;
      maxLongitude = point.longitude > maxLongitude ? point.longitude : maxLongitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLatitude, minLongitude),
      northeast: LatLng(maxLatitude, maxLongitude),
    );
  }
}
