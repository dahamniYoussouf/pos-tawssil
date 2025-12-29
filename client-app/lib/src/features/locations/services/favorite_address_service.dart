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
    String? name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
    String? iconUrl,
  }) async {
    final body = {
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
      if (iconUrl != null) 'icon_url': iconUrl,
    };
    if (name != null) {
      body['name'] = name;
    }
    return await postRequest('/client/favorite-addresses', data: body);
  }

  Future<Map<String, dynamic>> updateFavoriteAddress({
    required String id,
    String? name,
    required String address,
    required double lat,
    required double lng,
    required bool isDefault,
    String? iconUrl,
  }) async {
    final body = {
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
      if (iconUrl != null) 'icon_url': iconUrl,
    };
    if (name != null) {
      body['name'] = name;
    }
    return await putRequest('/client/favorite-addresses/$id', data: body);
  }

  Future<Map<String, dynamic>> deleteFavoriteAddress(String id) async {
    return await deleteRequest('/client/favorite-addresses/$id');
  }
}
