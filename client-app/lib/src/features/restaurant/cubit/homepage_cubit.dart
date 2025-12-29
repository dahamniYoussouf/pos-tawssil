import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/homepage_repository.dart';
import 'homepage_state.dart';

class HomepageCubit extends Cubit<HomepageState> {
  final HomepageRepository _homepageRepository;

  HomepageCubit({
    HomepageRepository? homepageRepository,
  })  : _homepageRepository = homepageRepository ?? HomepageRepository(),
        super(HomepageInitial());

  Future<void> loadHomepage({
    String? address,
    double? lat,
    double? lng,
    int radius = 2500,
    String? q,
    List<String>? categories,
    List<String>? homeCategories,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (isClosed) return;
    emit(HomepageLoading());

    try {
      // Get user coordinates
      // Get location from LocationCubit if available
      await locator<LocationCubit>().loadSavedLocation();
      final locationState = locator<LocationCubit>().state;
      double? lat;
      double? lng;

      if (locationState is LocationSuccess) {
        // use only coordinates if available
        if (locationState.latitude != null && locationState.longitude != null) {
          lat = locationState.latitude;
          lng = locationState.longitude;
        }
      }
      if (isClosed) return;
      if (lat == null || lng == null) {
        emit(const HomepageError(
            message:
                'Unable to get location. Please enable location services.'));
        return;
      }

      final result = await _homepageRepository.getHomepage(
        address: address,
        lat: lat,
        lng: lng,
        radius: radius,
        q: q,
        categories: categories,
        homeCategories: homeCategories,
        page: page,
        pageSize: pageSize,
      );
      if (isClosed) return;
      result.fold(
        (error) {
          if (!isClosed) {
            emit(HomepageError(message: error));
          }
        },
        (data) {
          if (!isClosed) {
            emit(HomepageLoaded(
              restaurants: data.restaurants,
              categories: data.categories,
              homepageData: data.homepageData,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(HomepageError(
          message: 'An unexpected error occurred: ${e.toString()}',
        ));
      }
    }
  }

  void clearError() {
    if (!isClosed && state is HomepageError) {
      emit(HomepageInitial());
    }
  }

  void resetToInitial() {
    if (!isClosed) {
      emit(HomepageInitial());
    }
  }
}
