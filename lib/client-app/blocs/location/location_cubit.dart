import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../services/location_service.dart' as location_service;
import '../../services/user_service.dart' as user_service;

// Location States
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied({required this.message});

  @override
  List<Object?> get props => [message];
}

class LocationGpsDisabled extends LocationState {}

class LocationPermissionGranted extends LocationState {}

class LocationSuccess extends LocationState {
  final String area;
  final String city;
  final String fullAddress;
  final double? latitude;
  final double? longitude;

  const LocationSuccess({
    required this.area,
    required this.city,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [area, city, fullAddress, latitude, longitude];
}

class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Location Cubit
class LocationCubit extends Cubit<LocationState> {
  final user_service.UserService _userService;

  LocationCubit({user_service.UserService? userService})
      : _userService = userService ?? user_service.UserService(),
        super(LocationInitial());

  Future<void> requestLocationPermission() async {
    emit(LocationLoading());
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        emit(const LocationPermissionDenied(
          message: 'Les autorisations de localisation sont définitivement refusées.'
        ));
        return;
      }
      
      if (permission == LocationPermission.denied) {
        emit(const LocationPermissionDenied(
          message: 'Autorisation de localisation refusée.'
        ));
        return;
      }
      
      emit(LocationPermissionGranted());
    } catch (e) {
      emit(LocationError(message: 'Erreur lors de la demande d\'autorisation: ${e.toString()}'));
    }
  }

  Future<void> getCurrentLocation() async {
    emit(LocationLoading());
    
    try {
      // Check if GPS is enabled
      bool gpsEnabled = await location_service.LocationService.isLocationServiceEnabled();
      if (!gpsEnabled) {
        emit(LocationGpsDisabled());
        return;
      }

      // Get current position
      Position? position = await location_service.LocationService.getCurrentLocation();
      if (position == null) {
        emit(const LocationError(message: 'Impossible de récupérer la localisation GPS.'));
        return;
      }

      // Reverse geocoding
      String area = '';
      String city = '';
      String fullAddress = '';
      
      try {
        List<geocoding.Placemark> placemarks = await geocoding
            .placemarkFromCoordinates(position.latitude, position.longitude);
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          area = (place.subLocality ?? place.locality ?? place.subAdministrativeArea ?? '').trim();
          city = (place.administrativeArea ?? place.country ?? '').trim();
          
          final parts = <String?>[
            place.name,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
            place.postalCode,
            place.country
          ].where((p) => p != null && p.trim().isNotEmpty).map((p) => p!.trim()).toList();
          
          fullAddress = parts.join(', ');
          if (fullAddress.isEmpty) {
            fullAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
          }
        } else {
          fullAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
          area = fullAddress;
          city = '';
        }
      } catch (e) {
        fullAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        area = fullAddress;
        city = '';
      }

      // Save to local storage
      await _userService.setCurrentLocationLatitude(position.latitude.toString());
      await _userService.setCurrentLocationLongitude(position.longitude.toString());
      await _userService.setCurrentLocation(area, city);
      await _userService.setFullAddress(fullAddress);

      // Send to server
      bool success = await _sendLocationToServer('', position.latitude, position.longitude);
      
      if (success) {
        emit(LocationSuccess(
          area: area,
          city: city,
          fullAddress: fullAddress,
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      } else {
        emit(const LocationError(message: 'Erreur lors de l\'envoi de la localisation. Vérifiez votre connexion.'));
      }
    } catch (e) {
      emit(LocationError(message: 'Erreur: ${e.toString()}'));
    }
  }

  Future<void> setManualAddress(String address) async {
    emit(LocationLoading());
    
    try {
      List<String> addressParts = address.split(',').map((e) => e.trim()).toList();
      String area = addressParts.isNotEmpty ? addressParts[0] : address;
      String city = addressParts.length > 1 ? addressParts[1] : address;
      
      double? latitude;
      double? longitude;
      
      // Try to geocode the manual address
      try {
        List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          latitude = loc.latitude;
          longitude = loc.longitude;
          await _userService.setCurrentLocationLatitude(latitude.toString());
          await _userService.setCurrentLocationLongitude(longitude.toString());
        }
      } catch (e) {
        // Geocoding failed, continue without coordinates
      }
      
      // Save to local storage
      await _userService.setCurrentLocation(area, city);
      await _userService.setFullAddress(address);
      
      // Send to server
      bool success = await _sendAddressToServer(address);
      
      if (success) {
        emit(LocationSuccess(
          area: area,
          city: city,
          fullAddress: address,
          latitude: latitude,
          longitude: longitude,
        ));
      } else {
        emit(const LocationError(message: 'Erreur lors de l\'envoi de l\'adresse. Vérifiez votre connexion.'));
      }
    } catch (e) {
      emit(LocationError(message: 'Erreur: ${e.toString()}'));
    }
  }

  Future<bool> _sendLocationToServer(String address, double latitude, double longitude) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        bool success = await location_service.LocationService.sendLocationWithCoordinates(address, latitude, longitude)
            .timeout(const Duration(seconds: 10));
        if (success) return true;
      } catch (e) {
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    return false;
  }

  Future<bool> _sendAddressToServer(String address) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        bool success = await location_service.LocationService.sendAddressOnly(address)
            .timeout(const Duration(seconds: 10));
        if (success) return true;
      } catch (e) {
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    return false;
  }

  void clearError() {
    if (state is LocationError) {
      emit(LocationInitial());
    }
  }

  Future<void> clearLocation() async {
    try {
      await _userService.clearLocation();
      emit(LocationInitial());
    } catch (e) {
      emit(LocationError(message: 'Erreur lors de la suppression de la localisation: ${e.toString()}'));
    }
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  void openAppSettings() {
    Geolocator.openAppSettings();
  }

  void resetLocation() {
    emit(LocationInitial());
  }
}