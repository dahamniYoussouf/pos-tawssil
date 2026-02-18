import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if GPS is enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check permissions
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // Reverse geocode coordinates to address
  static Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        geocoding.Placemark p = placemarks.first;

        List<String> addressParts = [];

        if (p.locality != null && p.locality!.isNotEmpty) {
          addressParts.add(p.locality!);
        } else if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          addressParts.add(p.subLocality!);
        }

        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          addressParts.add(p.administrativeArea!);
        }

        if (p.country != null && p.country!.isNotEmpty) {
          addressParts.add(p.country!);
        }

        String optimizedAddress = addressParts.join(', ');

        if (optimizedAddress.isEmpty) {
          optimizedAddress = "Alger, Algeria";
        }

        return optimizedAddress;
      }

      return "Alger, Algeria";
    } catch (e) {
      return "Alger, Algeria";
    }
  }

  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await checkLocationPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<void> openLocationSettings() async {
    await openAppSettings();
  }

  static Future<void> openGpsSettings() async {
    await Geolocator.openLocationSettings();
  }

  static String formatCoordinates(Position position) {
    return 'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${position.longitude.toStringAsFixed(6)}';
  }
}
