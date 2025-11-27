import 'package:geocoding/geocoding.dart' as geocoding;
import '../services/location_service.dart';
import '../repositories/location_repository.dart';

class SaveManualAddressUseCase {
  final LocationRepository _locationRepository;

  SaveManualAddressUseCase({
    LocationRepository? locationRepository,
    LocationService? locationService,
  }) : _locationRepository = locationRepository ?? LocationRepository();

  Future<ManualAddressResult> execute(String address) async {
    try {
      final List<String> addressParts = address.split(',').map((e) => e.trim()).toList();
      final String area = addressParts.isNotEmpty ? addressParts[0] : address;
      final String city = addressParts.length > 1 ? addressParts[1] : address;
      double? latitude;
      double? longitude;
      try {
        final List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          latitude = loc.latitude;
          longitude = loc.longitude;
          await _locationRepository.saveCoordinates(
            latitude: latitude.toString(),
            longitude: longitude.toString(),
          );
        }
      } catch (e) {
        // Geocoding failed, continue without coordinates
      }
      await _locationRepository.saveAreaAndCity(area: area, city: city);
      await _locationRepository.saveFullAddress(address);
      return ManualAddressResult.success(
        area: area,
        city: city,
        fullAddress: address,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      return ManualAddressResult.error(e.toString());
    }
  }
}

class ManualAddressResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? area;
  final String? city;
  final String? fullAddress;
  final double? latitude;
  final double? longitude;

  ManualAddressResult._({
    required this.isSuccess,
    this.errorMessage,
    this.area,
    this.city,
    this.fullAddress,
    this.latitude,
    this.longitude,
  });

  factory ManualAddressResult.success({
    required String area,
    required String city,
    required String fullAddress,
    double? latitude,
    double? longitude,
  }) {
    return ManualAddressResult._(
      isSuccess: true,
      area: area,
      city: city,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory ManualAddressResult.error(String message) {
    return ManualAddressResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
