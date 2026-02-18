import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as dev;

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Check if location services are enabled and permissions are granted
  /// Note: Does NOT request permissions — that is handled by LocationCubit.
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      dev.log('[LocationService] Location services are disabled.',
          name: 'LocationService');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      dev.log('[LocationService] Location permissions not granted: $permission',
          name: 'LocationService');
      return false;
    }

    return true;
  }

  /// Get the current position of the device
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      dev.log('[LocationService] Error getting current position: $e',
          name: 'LocationService');
      return null;
    }
  }

  /// Start listening to location changes
  void startTracking(Function(Position) onLocationChanged) async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    if (_positionStreamSubscription != null) {
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        dev.log(
          '[LocationService] Location updated: ${position.latitude}, ${position.longitude}',
          name: 'LocationService',
        );
        onLocationChanged(position);
      },
      onError: (error) {
        dev.log('[LocationService] Stream error: $error',
            name: 'LocationService');
      },
    );
  }

  /// Stop listening to location changes
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    dev.log('[LocationService] Tracking stopped', name: 'LocationService');
  }

  void dispose() {
    stopTracking();
  }
}
