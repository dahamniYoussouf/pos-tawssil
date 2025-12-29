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

      if (response['success'] != true) {
        emit(FavoriteAddressError(
          message: response['message'] as String? ?? 'Failed to load addresses',
        ));
        return;
      }

      final data = response['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        emit(const FavoriteAddressLoaded(addresses: []));
        return;
      }

      final addresses = <FavoriteAddressModel>[];
      for (final item in data) {
        try {
          if (item is Map<String, dynamic>) {
            final address = FavoriteAddressModel.fromJson(item);
            addresses.add(address);
          }
        } catch (e) {
          // Log parsing error but continue with other addresses
          print('Error parsing address: $e\nData: $item');
        }
      }

      emit(FavoriteAddressLoaded(addresses: addresses));
    } catch (e) {
      emit(FavoriteAddressError(
          message: 'Error loading addresses: ${e.toString()}'));
    }
  }

  Future<void> createFavoriteAddress({
    String? name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
    String? iconUrl,
  }) async {
    emit(FavoriteAddressLoading());
    try {
      final response = await _favoriteAddressService.createFavoriteAddress(
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
        iconUrl: iconUrl,
      );

      if (response['success'] != true) {
        emit(FavoriteAddressError(
          message: response['message'] as String? ?? 'Failed to create address',
        ));
        return;
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        emit(const FavoriteAddressError(message: 'Failed to create address'));
        return;
      }

      final createdAddress = FavoriteAddressModel.fromJson(data);
      emit(FavoriteAddressCreated(address: createdAddress));
      await loadFavoriteAddresses();
    } catch (e) {
      emit(FavoriteAddressError(
        message: 'Error creating address: ${e.toString()}',
      ));
    }
  }

  Future<void> updateFavoriteAddress({
    required String id,
    String? name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
    String? iconUrl,
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
        iconUrl: iconUrl,
      );

      if (response['success'] != true) {
        emit(FavoriteAddressError(
          message: response['message'] as String? ?? 'Failed to update address',
        ));
        return;
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        emit(const FavoriteAddressError(message: 'Failed to update address'));
        return;
      }

      final updatedAddress = FavoriteAddressModel.fromJson(data);
      emit(FavoriteAddressUpdated(address: updatedAddress));
      await loadFavoriteAddresses();
    } catch (e) {
      emit(FavoriteAddressError(
        message: 'Error updating address: ${e.toString()}',
      ));
    }
  }

  Future<void> deleteFavoriteAddress(String id) async {
    emit(FavoriteAddressLoading());
    try {
      final response = await _favoriteAddressService.deleteFavoriteAddress(id);

      if (response['success'] != true) {
        emit(FavoriteAddressError(
          message: response['message'] as String? ?? 'Failed to delete address',
        ));
        return;
      }

      emit(FavoriteAddressDeleted(addressId: id));
      await loadFavoriteAddresses();
    } catch (e) {
      emit(FavoriteAddressError(
        message: 'Error deleting address: ${e.toString()}',
      ));
    }
  }

  void resetState() {
    emit(FavoriteAddressInitial());
  }
}
