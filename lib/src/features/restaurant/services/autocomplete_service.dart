import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../auth/services/user_service.dart';

class AutocompleteService {
  final UserService _userService = UserService();

  Future<List<String>> getRestaurantSuggestions(String query) async {
    if (query.trim().length < 2) {
      return [];
    }

    try {
      // Get user coordinates for nearby search
      final coords = await _userService.getCurrentCoordinates();

      if (coords == null) {
        return [];
      }

      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/restaurant/getnearbynames'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'lat': coords['lat'],
          'lng': coords['lng'],
          'radius': 5000, // 5km radius
        }),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData.containsKey('data')) {
          final List<dynamic> namesList = responseData['data'];
          final List<String> allNames = namesList.cast<String>();

          // Filter names that contain the query (case-insensitive)
          final queryLower = query.toLowerCase().trim();
          final filteredNames = allNames.where((name) => name.toLowerCase().contains(queryLower)).toList();

          // Limit to 10 suggestions for better UX
          return filteredNames.take(10).toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
