import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:client_app/src/features/order/widgets/cubit/order_tracking_map_cubit.dart';

class OrderTrackingMap extends StatefulWidget {
  final OrderModel order;
  final double initialZoom;
  final double boundsPadding;

  const OrderTrackingMap({
    super.key,
    required this.order,
    this.initialZoom = 14,
    this.boundsPadding = 80,
  });

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap> {
  late final MapController _mapController;
  late final OrderTrackingMapCubit _mapCubit;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _mapCubit = OrderTrackingMapCubit()..updateOrder(widget.order);
  }

  @override
  void dispose() {
    _mapCubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OrderTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mapCubit.updateOrder(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTrackingMapCubit>.value(
      value: _mapCubit,
      child: BlocListener<OrderTrackingMapCubit, OrderTrackingMapState>(
        listenWhen: (OrderTrackingMapState previous, OrderTrackingMapState current) => previous.bounds != current.bounds,
        listener: (BuildContext context, OrderTrackingMapState state) {
          if (_isMapReady && state.bounds != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(state.bounds!));
          }
        },
        child: BlocBuilder<OrderTrackingMapCubit, OrderTrackingMapState>(
          builder: (BuildContext context, OrderTrackingMapState state) {
            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: state.center,
                initialZoom: widget.initialZoom,
                onMapReady: _handleMapReady,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tawsil.delivery',
                ),
                if (state.polylines.isNotEmpty)
                  PolylineLayer(
                    polylines: state.polylines,
                  ),
                if (state.markers.isNotEmpty)
                  MarkerLayer(
                    markers: state.markers,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleMapReady() {
    _isMapReady = true;
    final LatLngBounds? bounds = _mapCubit.state.bounds;
    if (bounds != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(bounds));
    }
  }

  void _fitBounds(LatLngBounds bounds) {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(widget.boundsPadding),
      ),
    );
  }
}
