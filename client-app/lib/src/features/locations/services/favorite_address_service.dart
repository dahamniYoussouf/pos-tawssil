import '../../../core/services/base_api_service.dart';

class FavoriteAddressService extends BaseApiService {
  static final FavoriteAddressService _instance =
      FavoriteAddressService._internal();
  factory FavoriteAddressService() => _instance;
  FavoriteAddressService._internal() : super();

  Future<Map<String, dynamic>> getFavoriteAddresses() async {
    return await getRequest('/client/favorite-addresses');
  }

  Future<Map<String, dynamic>> createFavoriteAddress({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
  }) async {
    final body = {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
    return await postRequest('/client/favorite-addresses', data: body);
  }

  Future<Map<String, dynamic>> updateFavoriteAddress({
    required String id,
    required String name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
  }) async {
    final body = {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
    return await putRequest('/client/favorite-addresses/$id', data: body);
  }

  Future<Map<String, dynamic>> deleteFavoriteAddress(String id) async {
    return await deleteRequest('/client/favorite-addresses/$id');
  }
}

