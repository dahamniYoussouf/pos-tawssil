import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/auth/models/location_selection.dart';
import 'package:restaurant_app/src/features/auth/services/location_geocoding_service.dart';

import 'location_search_state.dart';

class LocationSearchCubit extends Cubit<LocationSearchState> {
  final LocationGeocodingService _geocodingService;

  LocationSearchCubit({LocationGeocodingService? geocodingService})
      : _geocodingService = geocodingService ?? locator<LocationGeocodingService>(),
        super(const LocationSearchInitial());

  Future<void> searchLocation({
    required String query,
    required String emptyQueryMessage,
    required String notFoundMessage,
    required String genericErrorMessage,
  }) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      emit(LocationSearchError(message: emptyQueryMessage));
      return;
    }
    emit(const LocationSearchLoading());
    try {
      final LocationSelection selection = await _geocodingService.fetchCoordinates(address: trimmedQuery);
      emit(LocationSearchSuccess(selection: selection));
    } on LocationNotFoundException {
      emit(LocationSearchError(message: notFoundMessage));
    } catch (_) {
      emit(LocationSearchError(message: genericErrorMessage));
    }
  }

  void resetState() {
    emit(const LocationSearchInitial());
  }
}
