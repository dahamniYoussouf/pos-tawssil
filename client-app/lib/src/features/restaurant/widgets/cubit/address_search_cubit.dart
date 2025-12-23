import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/restaurant/services/google_places_service.dart';
import 'address_search_state.dart';

class AddressSearchCubit extends Cubit<AddressSearchState> {
  AddressSearchCubit() : super(AddressSearchInitial());

  /// Get autocomplete suggestions as user types
  Future<void> getAutocompleteSuggestions(String query) async {
    if (query.trim().isEmpty) {
      emit(AddressSearchInitial());
      return;
    }

    // Only search if query is at least 2 characters
    if (query.trim().length < 2) {
      emit(AddressSearchInitial());
      return;
    }

    emit(AddressSearchLoading());
    try {
      final predictions = await GooglePlacesService.getAutocompleteSuggestions(
        query.trim(),
      );

      if (predictions.isEmpty) {
        emit(const AddressSearchError(
            message: 'No locations found for this address'));
      } else {
        emit(AddressSearchSuggestions(predictions: predictions));
      }
    } catch (e) {
      emit(AddressSearchError(
          message: 'Error searching address: ${e.toString()}'));
    }
  }

  /// Select a place from autocomplete suggestions and get its details
  Future<void> selectPlace(PlacePrediction prediction) async {
    emit(AddressSearchLoading());
    try {
      final placeDetails = await GooglePlacesService.getPlaceDetails(
        prediction.placeId,
      );

      emit(AddressSearchSuccess(
        address: placeDetails.formattedAddress,
        latitude: placeDetails.latitude,
        longitude: placeDetails.longitude,
      ));
    } catch (e) {
      emit(AddressSearchError(
          message: 'Error getting place details: ${e.toString()}'));
    }
  }

  /// Legacy method for backward compatibility - now uses Google Places
  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) {
      emit(AddressSearchInitial());
      return;
    }

    emit(AddressSearchLoading());
    try {
      // Get autocomplete suggestions first
      final predictions = await GooglePlacesService.getAutocompleteSuggestions(
        query.trim(),
      );

      if (predictions.isEmpty) {
        emit(const AddressSearchError(
            message: 'No location found for this address'));
      } else {
        // Use the first prediction
        final placeDetails = await GooglePlacesService.getPlaceDetails(
          predictions.first.placeId,
        );

        emit(AddressSearchSuccess(
          address: placeDetails.formattedAddress,
          latitude: placeDetails.latitude,
          longitude: placeDetails.longitude,
        ));
      }
    } catch (e) {
      emit(AddressSearchError(
          message: 'Error searching address: ${e.toString()}'));
    }
  }

  void resetState() {
    emit(AddressSearchInitial());
  }
}
