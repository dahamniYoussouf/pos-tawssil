import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'address_search_state.dart';

class AddressSearchCubit extends Cubit<AddressSearchState> {
  AddressSearchCubit() : super(AddressSearchInitial());

  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) {
      emit(AddressSearchInitial());
      return;
    }
    emit(AddressSearchLoading());
    try {
      final List<Location> locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        emit(const AddressSearchError(
            message: 'No location found for this address'));
      } else {
        final location = locations.first;
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        String address = query;
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = _formatAddress(placemark);
        }
        emit(AddressSearchSuccess(
          address: address,
          latitude: location.latitude,
          longitude: location.longitude,
        ));
      }
    } catch (e) {
      emit(AddressSearchError(message: 'Error searching address: ${e.toString()}'));
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
    emit(AddressSearchInitial());
  }
}

