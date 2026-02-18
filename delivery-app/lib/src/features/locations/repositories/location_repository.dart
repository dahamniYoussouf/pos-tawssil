import 'package:shared_preferences/shared_preferences.dart';

class LocationRepository {
  static const String _locationAreaKey = 'location_area';
  static const String _locationCityKey = 'location_city';
  static const String _locationLatitudeKey = 'location_latitude';
  static const String _locationLongitudeKey = 'location_longitude';
  static const String _locationFullAddressKey = 'location_full_address';

  Future<bool> saveLocationData({
    required String area,
    required String city,
    required String latitude,
    required String longitude,
    required String fullAddress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_locationAreaKey, area),
        prefs.setString(_locationCityKey, city),
        prefs.setString(_locationLatitudeKey, latitude),
        prefs.setString(_locationLongitudeKey, longitude),
        prefs.setString(_locationFullAddressKey, fullAddress),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveCoordinates({
    required String latitude,
    required String longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_locationLatitudeKey, latitude),
        prefs.setString(_locationLongitudeKey, longitude),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveAreaAndCity({
    required String area,
    required String city,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_locationAreaKey, area),
        prefs.setString(_locationCityKey, city),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveFullAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_locationFullAddressKey, address);
    } catch (e) {
      return false;
    }
  }

  Future<String?> getFullAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_locationFullAddressKey);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>> getLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'area': prefs.getString(_locationAreaKey),
        'city': prefs.getString(_locationCityKey),
        'latitude': prefs.getString(_locationLatitudeKey),
        'longitude': prefs.getString(_locationLongitudeKey),
        'fullAddress': prefs.getString(_locationFullAddressKey),
      };
    } catch (e) {
      return {};
    }
  }

  Future<bool> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_locationAreaKey),
        prefs.remove(_locationCityKey),
        prefs.remove(_locationLatitudeKey),
        prefs.remove(_locationLongitudeKey),
        prefs.remove(_locationFullAddressKey),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
