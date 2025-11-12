import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/l10n/app_localizations.dart';

class UserLocation {
  final String area;
  final String city;

  UserLocation({required this.area, required this.city});
}

class UserService {
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  static const String _locationAreaKey = 'location_area';
  static const String _locationCityKey = 'location_city';
  static const String _locationLatitudeKey = 'location_latitude';
  static const String _locationLongitudeKey = 'location_longitude';

  Future<bool> setFullAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('location_full_address', address);
    } catch (e) {
      return false;
    }
  }

  // Get current location
  Future<UserLocation> getCurrentLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final area = prefs.getString(_locationAreaKey);
      final city = prefs.getString(_locationCityKey);

      // Try to get location from device if not set in prefs
      if (area == null || city == null) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          return UserLocation(area: 'Bararij', city: 'Sidi Moussa');
        }
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final areaName = place.locality ?? place.subLocality ?? 'Unknown area';
            final cityName = place.administrativeArea ?? 'Unknown city';
            return UserLocation(area: areaName, city: cityName);
          } else {
            return UserLocation(
              area: position.latitude.toString(),
              city: position.longitude.toString(),
            );
          }
        } catch (e) {
          return UserLocation(
            area: position.latitude.toString(),
            city: position.longitude.toString(),
          );
        }
      }
      return UserLocation(area: area, city: city);
    } catch (e) {
      return UserLocation(area: 'Bararij', city: 'Sidi Moussa');
    }
  }

  // Set current location
  Future<bool> setCurrentLocation(String area, String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final areaSuccess = await prefs.setString(_locationAreaKey, area);
      final citySuccess = await prefs.setString(_locationCityKey, city);

      return areaSuccess && citySuccess;
    } catch (e) {
      return false;
    }
  }

  // Save numeric coordinates (as strings) for later use
  Future<bool> setCurrentLocationLatitude(String latitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latSuccess = await prefs.setString(_locationLatitudeKey, latitude);
      return latSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setCurrentLocationLongitude(String longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lngSuccess = await prefs.setString(_locationLongitudeKey, longitude);
      return lngSuccess;
    } catch (e) {
      return false;
    }
  }

  // Get saved latitude as string (nullable)
  Future<String?> getCurrentLocationLatitude() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_locationLatitudeKey);
      return val;
    } catch (e) {
      return null;
    }
  }

  // Get saved longitude as string (nullable)
  Future<String?> getCurrentLocationLongitude() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_locationLongitudeKey);
      return val;
    } catch (e) {
      return null;
    }
  }

  // Get both coordinates as doubles if available
  Future<Map<String, double>?> getCurrentCoordinates() async {
    try {
      final latStr = await getCurrentLocationLatitude();
      final lngStr = await getCurrentLocationLongitude();
      if (latStr != null && lngStr != null) {
        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear location
  Future<bool> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationAreaKey);
      await prefs.remove(_locationCityKey);
      await prefs.remove(_locationLatitudeKey);
      await prefs.remove(_locationLongitudeKey);
      await prefs.remove('location_full_address');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get greeting message based on time
  String getGreetingMessage(AppLocalizations localizations) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return localizations.greetingMorning;
    } else if (hour < 17) {
      return localizations.greetingAfternoon;
    } else {
      return localizations.greetingEvening;
    }
  }

  // Clear all user data
  Future<bool> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      return false;
    }
  }
}
