import 'package:geocoding/geocoding.dart';
import 'package:restaurant_app/src/features/auth/models/location_selection.dart';

class LocationNotFoundException implements Exception {
  const LocationNotFoundException();
}

class LocationGeocodingService {
  const LocationGeocodingService();

  Future<LocationSelection> fetchCoordinates({required String address}) async {
    final List<Location> locations = await locationFromAddress(address);
    if (locations.isEmpty) {
      throw const LocationNotFoundException();
    }
    final Location location = locations.first;
    return LocationSelection(
      address: address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}
