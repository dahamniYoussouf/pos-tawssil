import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _usernameKey = 'username';
  static const String _locationAreaKey = 'location_area';
  static const String _locationCityKey = 'location_city';
  static const String _locationLatitudeKey = 'location_latitude';
  static const String _locationLongitudeKey = 'location_longitude';

  Future<bool> setFullAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('location_full_address', address);
    } catch (e) {
      print('Error saving full address: $e');
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get current username
  Future<String> getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey) ?? 'khouloud';
    } catch (e) {
      print('Error getting username: $e');
      return 'khouloud'; // Fallback on error
    }
  }

  // Set current username
  Future<bool> setCurrentUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_usernameKey, username);
    } catch (e) {
      print('Error setting username: $e');
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
        print('Location not found in prefs, using default: Bararij, Sidi Moussa');
        return UserLocation(
          area: 'Bararij',
          city: 'Sidi Moussa',
        );
      }
      print('Location from prefs: area=$area, city=$city');
      return UserLocation(area: area, city: city);
    } catch (e) {
      print('Error getting location: $e');
      // Return default location on error
      print('Using default location: Bararij, Sidi Moussa');
      return UserLocation(
        area: 'Bararij',
        city: 'Sidi Moussa',
      );
    }
  }

  // Set current location
  Future<bool> setCurrentLocation(String area, String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final areaSuccess = await prefs.setString(_locationAreaKey, area);
      final citySuccess = await prefs.setString(_locationCityKey, city);

      print('Location saved: $area, $city');
      return areaSuccess && citySuccess;
    } catch (e) {
      print('Error setting location: $e');
      return false;
    }
  }

  // Save numeric coordinates (as strings) for later use
  Future<bool> setCurrentLocationLatitude(String latitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latSuccess = await prefs.setString(_locationLatitudeKey, latitude);
      print('Latitude saved: $latitude');
      return latSuccess;
    } catch (e) {
      print('Error setting latitude: $e');
      return false;
    }
  }

  Future<bool> setCurrentLocationLongitude(String longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lngSuccess =
          await prefs.setString(_locationLongitudeKey, longitude);
      print('Longitude saved: $longitude');
      return lngSuccess;
    } catch (e) {
      print('Error setting longitude: $e');
      return false;
    }
  }

  // Get saved latitude as string (nullable)
  Future<String?> getCurrentLocationLatitude() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_locationLatitudeKey);
      print('🔎 getCurrentLocationLatitude -> $val');
      return val;
    } catch (e) {
      print('Error getting latitude: $e');
      return null;
    }
  }

  // Get saved longitude as string (nullable)
  Future<String?> getCurrentLocationLongitude() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_locationLongitudeKey);
      print('🔎 getCurrentLocationLongitude -> $val');
      return val;
    } catch (e) {
      print('Error getting longitude: $e');
      return null;
    }
  }

  // Get both coordinates as doubles if available
  Future<Map<String, double>?> getCurrentCoordinates() async {
    try {
      final latStr = await getCurrentLocationLatitude();
      final lngStr = await getCurrentLocationLongitude();
      print('🔎 getCurrentCoordinates raw -> lat: $latStr, lng: $lngStr');
      if (latStr != null && lngStr != null) {
        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        print('🔎 getCurrentCoordinates parsed -> lat: $lat, lng: $lng');
        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }
      return null;
    } catch (e) {
      print('Error getting current coordinates: $e');
      return null;
    }
  }

  // Clear location
  Future<bool> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationAreaKey);
      await prefs.remove(_locationCityKey);
      return true;
    } catch (e) {
      print('Error clearing location: $e');
      return false;
    }
  }

  // Get greeting message based on time
  String getGreetingMessage() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 17) {
      return 'Bonne après-midi';
    } else {
      return 'Bonsoir';
    }
  }

  // Clear all user data
  Future<bool> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }
}
