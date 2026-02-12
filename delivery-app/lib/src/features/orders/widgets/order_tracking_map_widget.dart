import 'dart:async';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_app/src/features/orders/widgets/cubit/order_tracking_map_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';

class OrderTrackingMap extends StatefulWidget {
  final OrderModel? order;
  final List<OrderModel>? orders;
  final double initialZoom;
  final double boundsPadding;

  const OrderTrackingMap({
    super.key,
    this.order,
    this.orders,
    this.initialZoom = 14,
    this.boundsPadding = 80,
  }) : assert(order != null || orders != null,
            'Either order or orders must be provided');

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    locator<OrderTrackingMapCubit>().initDriver(
      locator<DriverCubit>().driver,
    );
    if (widget.orders != null) {
      locator<OrderTrackingMapCubit>().updateOrders(widget.orders!);
    }
    _getCurrentLocation();
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
    if (widget.orders != null) {
      locator<OrderTrackingMapCubit>().updateOrders(widget.orders!);
    } else if (widget.order != null) {
      locator<OrderTrackingMapCubit>().updateOrder(widget.order!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTrackingMapCubit>.value(
      value: locator<OrderTrackingMapCubit>(),
      child: BlocListener<DriverCubit, DriverState>(
        listener: (BuildContext context, DriverState driverState) {
          if (driverState is DriverLoaded && mounted) {
            if (widget.orders != null) {
              locator<OrderTrackingMapCubit>().updateOrders(widget.orders!);
            } else if (widget.order != null) {
              locator<OrderTrackingMapCubit>().updateOrder(widget.order!);
            }
          }
        },
        child: BlocListener<OrderTrackingMapCubit, OrderTrackingMapState>(
          listenWhen:
              (OrderTrackingMapState previous, OrderTrackingMapState current) =>
                  previous.bounds != current.bounds,
          listener: (BuildContext context, OrderTrackingMapState state) {
            if (_mapController != null && state.bounds != null) {
              _fitBounds(state.bounds!);
            }
          },
          child: BlocBuilder<OrderTrackingMapCubit, OrderTrackingMapState>(
            builder: (BuildContext context, OrderTrackingMapState state) {
              final LatLng validCenter =
                  locator<DriverCubit>().driver?.latitude != null &&
                          locator<DriverCubit>().driver?.longitude != null
                      ? LatLng(locator<DriverCubit>().driver!.latitude!,
                          locator<DriverCubit>().driver!.longitude!)
                      : const LatLng(36.7538, 3.0588);

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: validCenter,
                  zoom: widget.initialZoom,
                ),
                markers: state.markers,
                polylines: state.polylines,
                onMapCreated: _onMapCreated,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              );
            },
          ),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final LatLngBounds? bounds = locator<OrderTrackingMapCubit>().state.bounds;
    if (bounds != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fitBounds(bounds);
        }
      });
    }
  }

  void _fitBounds(LatLngBounds bounds) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, widget.boundsPadding),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;
      final DriverCubit driverCubit = context.read<DriverCubit>();
      final DriverState driverState = driverCubit.state;
      if (driverState is DriverLoaded) {
        if (widget.orders != null) {
          locator<OrderTrackingMapCubit>().updateOrders(widget.orders!);
        } else if (widget.order != null) {
          locator<OrderTrackingMapCubit>().updateOrder(widget.order!);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
