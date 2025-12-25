import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../repositories/location_repository.dart';

class GetGpsLocationUseCase {
  final LocationRepository _locationRepository;

  GetGpsLocationUseCase({
    LocationRepository? locationRepository,
    LocationService? locationService,
  }) : _locationRepository = locationRepository ?? LocationRepository();

  Future<GpsLocationResult> execute() async {
    try {
      final bool isGpsEnabled =
          await LocationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        return GpsLocationResult.gpsDisabled();
      }
      final Position? position = await LocationService.getCurrentLocation();
      if (position == null) {
        return GpsLocationResult.error('Failed to get current position');
      }
      final AddressData addressData =
          await _getAddressFromCoordinates(position);
      await _saveLocationData(position, addressData);

      return GpsLocationResult.success(
        area: addressData.area,
        city: addressData.city,
        fullAddress: addressData.fullAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return GpsLocationResult.error(e.toString());
    }
  }

  Future<AddressData> _getAddressFromCoordinates(Position position) async {
    String area = '';
    String city = '';
    String fullAddress = '';
    try {
      final List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final geocoding.Placemark place = placemarks.first;
        area = (place.subLocality ??
                place.locality ??
                place.subAdministrativeArea ??
                '')
            .trim();
        city = (place.administrativeArea ?? place.country ?? '').trim();
        final List<String?> addressParts = [
          place.name,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ];
        final List<String> parts = addressParts
            .where((part) => part != null && part.trim().isNotEmpty)
            .map((part) => part!.trim())
            .toList();
        fullAddress = parts.join(', ');
        if (fullAddress.isEmpty) {
          fullAddress =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        }
      } else {
        fullAddress =
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        area = fullAddress;
        city = '';
      }
    } catch (e) {
      fullAddress =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
      area = fullAddress;
      city = '';
    }
    return AddressData(area: area, city: city, fullAddress: fullAddress);
  }

  Future<void> _saveLocationData(
      Position position, AddressData addressData) async {
    await _locationRepository.saveLocationData(
      area: addressData.area,
      city: addressData.city,
      latitude: position.latitude.toString(),
      longitude: position.longitude.toString(),
      fullAddress: addressData.fullAddress,
    );
  }
}

class AddressData {
  final String area;
  final String city;
  final String fullAddress;

  AddressData({
    required this.area,
    required this.city,
    required this.fullAddress,
  });
}

class GpsLocationResult {
  final bool isSuccess;
  final bool isGpsDisabled;
  final String? errorMessage;
  final String? area;
  final String? city;
  final String? fullAddress;
  final double? latitude;
  final double? longitude;

  GpsLocationResult._({
    required this.isSuccess,
    required this.isGpsDisabled,
    this.errorMessage,
    this.area,
    this.city,
    this.fullAddress,
    this.latitude,
    this.longitude,
  });

  factory GpsLocationResult.success({
    required String area,
    required String city,
    required String fullAddress,
    required double latitude,
    required double longitude,
  }) {
    return GpsLocationResult._(
      isSuccess: true,
      isGpsDisabled: false,
      area: area,
      city: city,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory GpsLocationResult.error(String message) {
    return GpsLocationResult._(
      isSuccess: false,
      isGpsDisabled: false,
      errorMessage: message,
    );
  }

  factory GpsLocationResult.gpsDisabled() {
    return GpsLocationResult._(
      isSuccess: false,
      isGpsDisabled: true,
    );
  }
}
