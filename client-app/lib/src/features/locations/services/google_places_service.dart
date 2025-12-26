import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client_app/src/core/config/api_config.dart';

/// Google Places Service (New API) optimized for Algeria
///
/// Uses the new Places API (New) from Google Cloud Console
/// Key optimizations:
/// - Country restriction to Algeria (DZ) using includedRegionCodes
/// - Language support for Arabic (default), French, and English
/// - Location bias to Algeria's center for better result ranking
/// - Includes all address types (streets, intersections, neighborhoods, etc.)
class GooglePlacesService {
  // New Google Places API endpoints
  static const String _autocompleteBaseUrl =
      'https://places.googleapis.com/v1/places:autocomplete';
  static const String _placeDetailsBaseUrl =
      'https://places.googleapis.com/v1/places/';

  // Algeria center coordinates for location bias
  static const double _algeriaCenterLat = 28.0339;
  static const double _algeriaCenterLng = 1.6596;
  static const int _algeriaRadiusMeters = 50000;

  /// Get autocomplete suggestions for a search query
  /// Optimized for Algeria with location bias, country restriction, and language support
  /// Returns a list of place predictions
  static Future<List<PlacePrediction>> getAutocompleteSuggestions(
    String query, {
    String? apiKey,
    String? sessionToken,
    String? languageCode,
  }) async {
    try {
      final key = apiKey ?? ApiConfig.googlePlacesApiKey;
      final lang = languageCode ?? 'ar';

      final requestBody = <String, dynamic>{
        'input': query,
        'languageCode': lang,
        'includedRegionCodes': ['DZ'],
        'locationBias': {
          'circle': {
            'center': {
              'latitude': _algeriaCenterLat,
              'longitude': _algeriaCenterLng,
            },
            'radius': _algeriaRadiusMeters,
          },
        },
      };

      if (sessionToken != null) {
        requestBody['sessionToken'] = sessionToken;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'suggestions.placePrediction',
      };

      final response = await http.post(
        Uri.parse(_autocompleteBaseUrl),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List?;
        if (suggestions != null && suggestions.isNotEmpty) {
          return suggestions
              .map((s) => PlacePrediction.fromNewApiJson(s))
              .toList();
        }
        return [];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Places API error: ${errorData['error']?['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get autocomplete suggestions: $e');
    }
  }

  /// Get place details including latitude and longitude
  /// Requires a place_id from autocomplete results
  /// Optimized for Algeria with language support
  static Future<PlaceDetails> getPlaceDetails(
    String placeId, {
    String? apiKey,
    String? sessionToken,
    String? languageCode,
  }) async {
    try {
      final key = apiKey ?? ApiConfig.googlePlacesApiKey;
      final lang = languageCode ?? 'ar';

      final queryParams = <String, String>{
        'languageCode': lang,
      };

      if (sessionToken != null) {
        queryParams['sessionToken'] = sessionToken;
      }

      final headers = <String, String>{
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'id,formattedAddress,location,displayName',
      };

      final uri = Uri.parse('$_placeDetailsBaseUrl$placeId')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetails.fromNewApiJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Places API error: ${errorData['error']?['message'] ?? response.statusCode}',
        );
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

  factory PlacePrediction.fromNewApiJson(Map<String, dynamic> json) {
    final placePrediction = json['placePrediction'] ?? {};
    final placeId = json['placeId'] ?? '';
    final text = placePrediction['text'] ?? {};
    final structuredFormat = placePrediction['structuredFormat'] ?? {};

    final mainText =
        structuredFormat['mainText']?['text'] ?? text['text'] ?? '';
    final secondaryText = structuredFormat['secondaryText']?['text'] ?? '';

    return PlacePrediction(
      placeId: placeId,
      description: text['text'] ?? mainText,
      mainText: mainText,
      secondaryText: secondaryText,
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

  factory PlaceDetails.fromNewApiJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    final displayName = json['displayName'] ?? {};
    return PlaceDetails(
      placeId: json['id'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      name: displayName['text'],
      latitude: (location['latitude'] ?? 0.0).toDouble(),
      longitude: (location['longitude'] ?? 0.0).toDouble(),
    );
  }
}
