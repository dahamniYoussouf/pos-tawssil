import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:shared_preferences/shared_preferences.dart';
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
}
