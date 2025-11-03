import 'package:frontend/src/core/services/token_storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/core/utils/dependency_injection.dart';
import '../../../core/services/base_api_service.dart';

class LocationService extends BaseApiService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal() : super();

  // Vérifier si le GPS est activé
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Vérifier les permissions
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  static const String _locationFullAddressKey = 'location_full_address';

  // Récupérer la position actuelle
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

  // Convertir les coordonnées en adresse compatible OpenStreetMap
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        geocoding.Placemark p = placemarks.first;

        // Format optimisé pour OpenStreetMap (utilisé par le backend)
        // Priorité: ville, région, pays (format simple et standard)
        List<String> addressParts = [];

        // Ajouter la ville/localité en premier
        if (p.locality != null && p.locality!.isNotEmpty) {
          addressParts.add(p.locality!);
        } else if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          addressParts.add(p.subLocality!);
        }

        // Ajouter la région administrative
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          addressParts.add(p.administrativeArea!);
        }

        // Ajouter le pays
        if (p.country != null && p.country!.isNotEmpty) {
          addressParts.add(p.country!);
        }

        String optimizedAddress = addressParts.join(', ');

        // Si l'adresse est vide, utiliser une adresse générique pour l'Algérie
        if (optimizedAddress.isEmpty) {
          optimizedAddress = "Alger, Algeria";
        }

        return optimizedAddress;
      }

      return "Alger, Algeria"; // Fallback pour l'Algérie
    } catch (e) {
      return "Alger, Algeria"; // Fallback par défaut
    }
  }

  // Envoyer localisation GPS (avec coordonnées) au serveur
  Future<bool> sendGpsLocationToServer(double latitude, double longitude) async {
    try {
      final url = ApiConfig.searchRestaurantsUrl;

      // Pour GPS: envoyer seulement les coordonnées
      final Map<String, dynamic> body = {
        'lat': latitude,
        'lng': longitude,
      };

      // Get token from storage
      final token = await locator<TokenStorageService>().getAccessToken();
      if (token == null) {
        return false;
      }

      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await dio.post(
        url,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // If backend echoes a 'center' in response, persist those coords for later use
        try {
          final dynamic resp = response.data is Map ? response.data : jsonDecode(response.data);
          if (resp is Map<String, dynamic> && resp.containsKey('center')) {
            final center = resp['center'];
            if (center is Map<String, dynamic>) {
              final lat = center['lat'];
              final lng = center['lng'];
              if (lat != null && lng != null) {
                await UserService().setCurrentLocationLatitude(lat.toString());
                await UserService().setCurrentLocationLongitude(lng.toString());
              }
            }
          }
        } catch (e) {
          // Could not parse backend center from response
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Envoyer la localisation avec coordonnées (cas GPS)
  Future<bool> sendLocationWithCoordinates(String address, double latitude, double longitude) async {
    try {
      final url = ApiConfig.searchRestaurantsUrl;

      final Map<String, dynamic> body = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
      };

      // Get token from storage
      final token = await locator<TokenStorageService>().getAccessToken();

      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await dio.post(
        url,
        data: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Envoyer adresse manuelle au serveur
  Future<bool> sendAddressOnly(String address) async {
    try {
      // D'abord, essayer de géocoder l'adresse pour obtenir les coordonnées
      try {
        List<geocoding.Location> locations = await geocoding.locationFromAddress(address);

        if (locations.isNotEmpty) {
          // Si on trouve des coordonnées, utiliser la méthode complète
          geocoding.Location location = locations.first;

          return await sendLocationWithCoordinates(address, location.latitude, location.longitude);
        }
      } catch (e) {
        // Échec du géocodage, envoi avec adresse seule
      }

      // Si le géocodage échoue, essayer d'envoyer quand même l'adresse seule
      final url = ApiConfig.searchRestaurantsUrl;

      final Map<String, dynamic> body = {
        'address': address,
      };

      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await dio.post(
        url,
        data: body,
      );

      // Persist backend center coords if present
      try {
        final dynamic resp = response.data is Map ? response.data : jsonDecode(response.data);
        if (resp is Map<String, dynamic> && resp.containsKey('center')) {
          final center = resp['center'];
          if (center is Map<String, dynamic>) {
            final lat = center['lat'];
            final lng = center['lng'];
            if (lat != null && lng != null) {
              await UserService().setCurrentLocationLatitude(lat.toString());
              await UserService().setCurrentLocationLongitude(lng.toString());
            }
          }
        }
      } catch (e) {
        // Could not parse backend center from response
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 500) {
        // Essayer avec des coordonnées par défaut pour l'Algérie
        return await sendLocationWithCoordinates(address, 36.7538, 3.0588); // Coordonnées d'Alger
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await checkLocationPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
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

class UserService {
  Future<void> setCurrentLocationLatitude(String latitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_location_latitude', latitude);
  }

  Future<void> setCurrentLocationLongitude(String longitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_location_longitude', longitude);
  }

  Future<void> setCurrentLocation({required String latitude, required String longitude}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_location_latitude', latitude);
    await prefs.setString('current_location_longitude', longitude);
  }

  Future<void> setCurrentLocationAreaCity({required String area, required String city}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_location_area', area);
    await prefs.setString('current_location_city', city);
  }

  Future<String?> getCurrentLocationLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_location_latitude');
  }

  Future<String?> getCurrentLocationLongitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_location_longitude');
  }

  Future<String?> getCurrentLocationArea() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_location_area');
  }

  Future<String?> getCurrentLocationCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_location_city');
  }

  static const String _locationFullAddressKey = 'location_full_address';

  Future<bool> setFullAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_locationFullAddressKey, address);
    } catch (e) {
      return false;
    }
  }
}
