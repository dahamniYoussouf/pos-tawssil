import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client_app/src/core/config/api_config.dart';

/// Google Places Service optimized for Algeria
///
/// Key optimizations:
/// - Country restriction to Algeria (DZ) using components parameter
/// - Language support for Arabic (default), French, and English
/// - Location bias to Algeria's center for better result ranking
/// - Uses 'geocode' type instead of 'address' for broader address coverage
///   (includes streets, intersections, neighborhoods, etc.)
class GooglePlacesService {
  // Google Places API endpoints
  static const String _autocompleteBaseUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _placeDetailsBaseUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  // Algeria center coordinates for location bias
  static const double _algeriaCenterLat = 28.0339;
  static const double _algeriaCenterLng = 1.6596;
  static const int _algeriaRadiusMeters =
      2000000; // ~2000km radius to cover all of Algeria

  /// Get autocomplete suggestions for a search query
  /// Optimized for Algeria with location bias, country restriction, and language support
  /// Returns a list of place predictions
  static Future<List<PlacePrediction>> getAutocompleteSuggestions(
    String query, {
    String? apiKey,
    String? sessionToken,
    String? languageCode, // 'ar', 'fr', or 'en' - defaults to 'ar' for Algeria
  }) async {
    try {
      final key = apiKey ?? ApiConfig.googlePlacesApiKey;

      // Default to Arabic for Algeria, but allow override
      final lang = languageCode ?? 'ar';

      // Build query parameters optimized for Algeria
      final queryParams = <String, String>{
        'input': query,
        'key': key,
        'language': lang, // Support Arabic, French, or English
        'components': 'country:dz', // Restrict to Algeria only
        // Location bias to prioritize Algeria results
        // Format: circle:radius@lat,lng
        'location': '$_algeriaCenterLat,$_algeriaCenterLng',
        'radius': '$_algeriaRadiusMeters',
        // Use 'geocode' instead of 'address' for better coverage in Algeria
        // 'geocode' includes addresses, streets, intersections, etc.
        'types':
            'geocode', // Better than 'address' - includes more address types
      };

      if (sessionToken != null) {
        queryParams['sessiontoken'] = sessionToken;
      }

      final uri =
          Uri.parse(_autocompleteBaseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List?;
          if (predictions != null) {
            return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
          }
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get autocomplete suggestions: $e');
    }

    return [];
  }

  /// Get place details including latitude and longitude
  /// Requires a place_id from autocomplete results
  /// Optimized for Algeria with language support
  static Future<PlaceDetails> getPlaceDetails(
    String placeId, {
    String? apiKey,
    String? sessionToken,
    String? languageCode, // 'ar', 'fr', or 'en' - defaults to 'ar' for Algeria
  }) async {
    try {
      final key = apiKey ?? ApiConfig.googlePlacesApiKey;

      // Default to Arabic for Algeria, but allow override
      final lang = languageCode ?? 'ar';

      final queryParams = <String, String>{
        'place_id': placeId,
        'key': key,
        'language': lang, // Support Arabic, French, or English
        'fields': 'formatted_address,geometry,name,address_components',
      };

      if (sessionToken != null) {
        queryParams['sessiontoken'] = sessionToken;
      }

      final uri =
          Uri.parse(_placeDetailsBaseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get place details: $e');
    }
  }
}

/// Represents a place prediction from autocomplete
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }
}

/// Represents detailed place information including coordinates
class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final String? name;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    this.name,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'],
      latitude: (location['lat'] ?? 0.0).toDouble(),
      longitude: (location['lng'] ?? 0.0).toDouble(),
    );
  }
}
