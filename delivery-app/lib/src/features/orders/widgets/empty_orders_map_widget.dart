import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:delivery_app/l10n/app_localizations.dart';

class EmptyOrdersMapWidget extends StatefulWidget {
  final VoidCallback? onRefresh;

  const EmptyOrdersMapWidget({
    super.key,
    this.onRefresh,
  });

  @override
  State<EmptyOrdersMapWidget> createState() => _EmptyOrdersMapWidgetState();
}

class _EmptyOrdersMapWidgetState extends State<EmptyOrdersMapWidget> {
  late final MapController _mapController;
  static const LatLng _defaultLocation = LatLng(36.7538, 3.0588);
  LatLng? _lastLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLng _getCurrentLocation(DriverState driverState) {
    if (driverState is DriverLoaded) {
      final driver = driverState.driver;
      if (driver.latitude != null && driver.longitude != null) {
        final newLocation = LatLng(driver.latitude!, driver.longitude!);
        if (_lastLocation == null || _lastLocation!.latitude != newLocation.latitude || _lastLocation!.longitude != newLocation.longitude) {
          _lastLocation = newLocation;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(newLocation, 15.0);
            }
          });
        }
        return newLocation;
      }
    }
    _lastLocation = _defaultLocation;
    return _defaultLocation;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, driverState) {
        final currentLocation = _getCurrentLocation(driverState);
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tawsil.delivery',
                ),
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: currentLocation,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  MediaRes.logo,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: widget.onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  localizations.retry,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
