import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:delivery_app/src/features/orders/widgets/cubit/order_tracking_map_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:latlong2/latlong.dart';

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
  }) : assert(order != null || orders != null, 'Either order or orders must be provided');

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap> {
  late final MapController _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
    _mapController.dispose();
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
          listenWhen: (OrderTrackingMapState previous, OrderTrackingMapState current) => previous.bounds != current.bounds,
          listener: (BuildContext context, OrderTrackingMapState state) {
            if (_isMapReady && state.bounds != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(state.bounds!));
            }
          },
          child: BlocBuilder<OrderTrackingMapCubit, OrderTrackingMapState>(
            builder: (BuildContext context, OrderTrackingMapState state) {
              final LatLng validCenter =
                  locator<DriverCubit>().driver?.latitude != null && locator<DriverCubit>().driver?.longitude != null ? LatLng(locator<DriverCubit>().driver!.latitude!, locator<DriverCubit>().driver!.longitude!) : const LatLng(36.7538, 3.0588);

              final double validZoom = widget.initialZoom.clamp(1.0, 18.0);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: validCenter,
                  initialZoom: validZoom,
                  minZoom: 1.0,
                  maxZoom: 18.0,
                  onMapReady: _handleMapReady,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tawsil.delivery',
                    maxZoom: 18,
                    minZoom: 1,
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
      ),
    );
  }

  void _handleMapReady() {
    _isMapReady = true;
    final LatLngBounds? bounds = locator<OrderTrackingMapCubit>().state.bounds;
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
