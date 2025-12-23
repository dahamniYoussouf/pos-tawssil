import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'map_location_state.dart';

class MapLocationCubit extends Cubit<MapLocationState> {
  MapLocationCubit() : super(MapLocationInitial());

  Future<void> updateLocation(double latitude, double longitude) async {
    emit(MapLocationLoading());
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      String address = 'Unknown location';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        address = _formatAddress(placemark);
      }
      emit(MapLocationSuccess(
        address: address,
        latitude: latitude,
        longitude: longitude,
      ));
    } catch (e) {
      emit(MapLocationError(message: 'Error getting address: ${e.toString()}'));
    }
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    return parts.join(', ');
  }

  void resetState() {
    emit(MapLocationInitial());
  }
}

