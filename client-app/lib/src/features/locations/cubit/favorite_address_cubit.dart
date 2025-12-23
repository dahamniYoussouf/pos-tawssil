import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/favorite_address_model.dart';
import '../services/favorite_address_service.dart';
import 'favorite_address_state.dart';

class FavoriteAddressCubit extends Cubit<FavoriteAddressState> {
  final FavoriteAddressService _favoriteAddressService;

  FavoriteAddressCubit({
    FavoriteAddressService? favoriteAddressService,
  })  : _favoriteAddressService =
            favoriteAddressService ?? FavoriteAddressService(),
        super(FavoriteAddressInitial());

  Future<void> loadFavoriteAddresses() async {
    emit(FavoriteAddressLoading());
    try {
      final response = await _favoriteAddressService.getFavoriteAddresses();
      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        if (data != null) {
          final addresses = data
              .map((json) => FavoriteAddressModel.fromJson(
                  json as Map<String, dynamic>))
              .toList();
          emit(FavoriteAddressLoaded(addresses: addresses));
        } else {
          emit(const FavoriteAddressLoaded(addresses: []));
        }
      } else {
        emit(FavoriteAddressError(
            message: response['message'] as String? ?? 'Failed to load addresses'));
      }
    } catch (e) {
      emit(FavoriteAddressError(message: 'Error: ${e.toString()}'));
    }
  }

  Future<void> createFavoriteAddress({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
  }) async {
    emit(FavoriteAddressLoading());
    try {
      final response = await _favoriteAddressService.createFavoriteAddress(
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          final createdAddress = FavoriteAddressModel.fromJson(data);
          emit(FavoriteAddressCreated(address: createdAddress));
          await loadFavoriteAddresses();
        } else {
          emit(const FavoriteAddressError(
              message: 'Failed to create address'));
        }
      } else {
        emit(FavoriteAddressError(
            message: response['message'] as String? ?? 'Failed to create address'));
      }
    } catch (e) {
      emit(FavoriteAddressError(message: 'Error: ${e.toString()}'));
    }
  }

  Future<void> updateFavoriteAddress({
    required String id,
    required String name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
  }) async {
    emit(FavoriteAddressLoading());
    try {
      final response = await _favoriteAddressService.updateFavoriteAddress(
        id: id,
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          final updatedAddress = FavoriteAddressModel.fromJson(data);
          emit(FavoriteAddressUpdated(address: updatedAddress));
          await loadFavoriteAddresses();
        } else {
          emit(const FavoriteAddressError(
              message: 'Failed to update address'));
        }
      } else {
        emit(FavoriteAddressError(
            message: response['message'] as String? ?? 'Failed to update address'));
      }
    } catch (e) {
      emit(FavoriteAddressError(message: 'Error: ${e.toString()}'));
    }
  }

  Future<void> deleteFavoriteAddress(String id) async {
    emit(FavoriteAddressLoading());
    try {
      final response = await _favoriteAddressService.deleteFavoriteAddress(id);
      if (response['success'] == true) {
        emit(FavoriteAddressDeleted(addressId: id));
        await loadFavoriteAddresses();
      } else {
        emit(FavoriteAddressError(
            message: response['message'] as String? ?? 'Failed to delete address'));
      }
    } catch (e) {
      emit(FavoriteAddressError(message: 'Error: ${e.toString()}'));
    }
  }

  void resetState() {
    emit(FavoriteAddressInitial());
  }
}

