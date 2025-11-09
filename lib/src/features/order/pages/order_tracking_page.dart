import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/core/res/color_app.dart';
import 'package:frontend/src/features/order/widgets/delivery_person_card_widget.dart';
import 'package:frontend/src/features/order/widgets/order_details_card_widget.dart';
import 'package:frontend/src/features/order/widgets/order_timeline_widget.dart';
import 'package:frontend/src/features/order/widgets/order_tracking_map_widget.dart';
import 'package:frontend/src/features/order/widgets/status_card_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../models/order_model.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});
  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  GoogleMapController? _mapController;
  Timer? _countdownTimer;
  Duration? _remainingTime;
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};
  OrderModel? _currentOrder;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _executeInitialLoad();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mapController?.dispose();
    context.read<OrderCubit>().stopPolling();
    super.dispose();
  }

  void _executeInitialLoad() {
    context.read<OrderCubit>().fetchOrder(widget.orderId);
    context.read<OrderCubit>().startPolling();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (BuildContext context, OrderState state) => _handleStateListener(context, state, localization),
        builder: (BuildContext context, OrderState state) => _buildStateBody(context, state, localization),
      ),
    );
  }

  void _handleStateListener(BuildContext context, OrderState state, AppLocalizations localization) {
    if (state is OrderLoaded || state is OrderRefused || state is OrderDelayed) {
      final OrderModel order = _extractOrderFromState(state);
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }
      _handleOrderUpdate(order);
    }
    if (state is OrderError && _isInitialLoad) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: ColorApp.redColor,
        ),
      );
    }
    if (state is OrderRefused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.orderRefused}: ${state.reason}'),
          backgroundColor: ColorApp.orangeColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    if (state is OrderDelayed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.orderDelayed}: ${state.reason}'),
          backgroundColor: ColorApp.orangeColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildStateBody(BuildContext context, OrderState state, AppLocalizations localization) {
    if ((state is OrderLoading || state is OrderInitial) && _isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is OrderError && _isInitialLoad) {
      return _buildInitialError(context, state, localization);
    }
    final OrderModel? order = _currentOrder ?? _extractOrderFromStateOrNull(state);
    if (order != null) {
      return _buildOrderTrackingContent(context, order, localization);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInitialError(BuildContext context, OrderError state, AppLocalizations localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _isInitialLoad = true;
              context.read<OrderCubit>().refreshOrder();
            },
            child: Text(localization.retry),
          ),
        ],
      ),
    );
  }

  OrderModel _extractOrderFromState(OrderState state) {
    if (state is OrderLoaded) {
      return state.order;
    }
    if (state is OrderRefused) {
      return state.order;
    }
    return (state as OrderDelayed).order;
  }

  OrderModel? _extractOrderFromStateOrNull(OrderState state) {
    if (state is OrderLoaded) {
      return state.order;
    }
    if (state is OrderRefused) {
      return state.order;
    }
    if (state is OrderDelayed) {
      return state.order;
    }
    return null;
  }

  Widget _buildOrderTrackingContent(BuildContext context, OrderModel order, AppLocalizations localization) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: OrderTrackingMap(
            initialCameraPosition: _createInitialCameraPosition(order),
            markers: Set<Marker>.of(_markers),
            polylines: Set<Polyline>.of(_polylines),
            onMapCreated: (GoogleMapController controller) => _handleMapCreated(controller, order),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 2,
          left: 16,
          child: SafeArea(
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        _buildContentSheet(order, localization),
      ],
    );
  }

  Widget _buildContentSheet(OrderModel order, AppLocalizations localization) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                StatusCardWidget(order: order, remainingTime: _remainingTime),
                const SizedBox(height: 16),
                OrderDetailsCard(order: order),
                const SizedBox(height: 16),
                if (order.isDelivering && order.deliveryPerson != null) DeliveryPersonCard(person: order.deliveryPerson!, localization: localization),
                if (order.isDelivering && order.deliveryPerson != null) const SizedBox(height: 16),
                OrderTimeline(order: order, localization: localization),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMapCreated(GoogleMapController controller, OrderModel order) {
    _mapController = controller;
    if (_hasRequiredCoordinates(order)) {
      final LatLng restaurantLatLng = _createRestaurantLatLng(order);
      final LatLng deliveryLatLng = _createDeliveryLatLng(order);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMarkersInBounds(restaurantLatLng, deliveryLatLng);
      });
    }
  }

  CameraPosition _createInitialCameraPosition(OrderModel order) {
    final LatLng fallback = const LatLng(36.7538, 3.0588);
    final LatLng target = order.restaurantLatitude != null && order.restaurantLongitude != null ? LatLng(order.restaurantLatitude!, order.restaurantLongitude!) : fallback;
    return CameraPosition(target: target, zoom: 12);
  }

  void _updateMap(OrderModel order) {
    if (!_hasRequiredCoordinates(order)) {
      return;
    }
    final LatLng restaurantLatLng = _createRestaurantLatLng(order);
    final LatLng deliveryLatLng = _createDeliveryLatLng(order);
    _resetMapData();
    _markers.addAll(_buildMarkers(order, restaurantLatLng, deliveryLatLng));
    _polylines.add(_buildRoutePolyline(restaurantLatLng, deliveryLatLng));
    _fitMarkersInBounds(restaurantLatLng, deliveryLatLng);
  }

  void _fitMarkersInBounds(LatLng point1, LatLng point2) {
    if (_mapController == null) {
      return;
    }
    final double minLat = point1.latitude < point2.latitude ? point1.latitude : point2.latitude;
    final double maxLat = point1.latitude > point2.latitude ? point1.latitude : point2.latitude;
    final double minLng = point1.longitude < point2.longitude ? point1.longitude : point2.longitude;
    final double maxLng = point1.longitude > point2.longitude ? point1.longitude : point2.longitude;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  void _startCountdownTimer(DateTime? estimatedDeliveryTime) {
    _countdownTimer?.cancel();
    if (estimatedDeliveryTime == null) {
      setState(() => _remainingTime = null);
      return;
    }
    final DateTime now = DateTime.now();
    if (estimatedDeliveryTime.isBefore(now)) {
      setState(() => _remainingTime = Duration.zero);
      return;
    }
    _remainingTime = estimatedDeliveryTime.difference(now);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final DateTime current = DateTime.now();
      if (estimatedDeliveryTime.isBefore(current)) {
        setState(() => _remainingTime = Duration.zero);
        timer.cancel();
        return;
      }
      setState(() => _remainingTime = estimatedDeliveryTime.difference(current));
    });
  }

  void _handleOrderUpdate(OrderModel order) {
    final bool isFirstLoad = _currentOrder == null;
    final bool hasOrderChanged = isFirstLoad ||
        _currentOrder?.status != order.status ||
        _currentOrder?.deliveryPerson?.id != order.deliveryPerson?.id ||
        _currentOrder?.deliveryPerson?.latitude != order.deliveryPerson?.latitude ||
        _currentOrder?.deliveryPerson?.longitude != order.deliveryPerson?.longitude ||
        _currentOrder?.estimatedDeliveryTime != order.estimatedDeliveryTime;
    _currentOrder = order;
    if (hasOrderChanged) {
      _updateMap(order);
      _startCountdownTimer(order.estimatedDeliveryTime);
    }
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

  void _resetMapData() {
    _markers.clear();
    _polylines.clear();
  }

  Set<Marker> _buildMarkers(OrderModel order, LatLng restaurantLatLng, LatLng deliveryLatLng) {
    final Set<Marker> markers = <Marker>{
      Marker(
        markerId: const MarkerId('restaurant'),
        position: restaurantLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: order.restaurantName ?? 'Restaurant',
        ),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: deliveryLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: order.deliveryAddress ?? '',
        ),
      ),
    };
    if (order.isDelivering && order.deliveryPerson != null) {
      final DeliveryPerson person = order.deliveryPerson!;
      if (person.latitude != null && person.longitude != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('delivery_person'),
            position: LatLng(person.latitude!, person.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: person.name,
              snippet: 'Delivery Person',
            ),
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
}
