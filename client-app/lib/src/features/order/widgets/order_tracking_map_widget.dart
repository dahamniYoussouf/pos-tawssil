import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/features/order/models/order_model.dart';
import 'package:client_app/src/features/order/widgets/cubit/order_tracking_map_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  GoogleMapController? _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    final cubit = locator<OrderTrackingMapCubit>();
    if (!cubit.isClosed) {
      cubit.updateOrder(widget.order);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OrderTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;
    final cubit = locator<OrderTrackingMapCubit>();
    if (!cubit.isClosed) {
      cubit.updateOrder(widget.order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTrackingMapCubit>.value(
      value: locator<OrderTrackingMapCubit>(),
      child: BlocListener<OrderTrackingMapCubit, OrderTrackingMapState>(
        listenWhen:
            (OrderTrackingMapState previous, OrderTrackingMapState current) =>
                previous.bounds != current.bounds,
        listener: (BuildContext context, OrderTrackingMapState state) {
          if (_isMapReady && state.bounds != null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _fitBounds(state.bounds!));
          }
        },
        child: BlocBuilder<OrderTrackingMapCubit, OrderTrackingMapState>(
          builder: (BuildContext context, OrderTrackingMapState state) {
            return GoogleMap(
              onMapCreated: _handleMapCreated,
              initialCameraPosition: CameraPosition(
                target: state.center,
                zoom: widget.initialZoom,
              ),
              markers: Set<Marker>.from(state.markers),
              // polylines: Set<Polyline>.from(state.polylines),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            );
          },
        ),
      ),
    );
  }

  void _handleMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    final LatLngBounds? bounds = locator<OrderTrackingMapCubit>().state.bounds;
    if (bounds != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(bounds));
    }
  }

  void _fitBounds(LatLngBounds bounds) {
    if (_mapController == null) {
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, widget.boundsPadding),
    );
  }
}
