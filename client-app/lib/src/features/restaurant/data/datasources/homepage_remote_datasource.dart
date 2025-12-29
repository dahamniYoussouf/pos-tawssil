import '../../../../core/services/base_api_service.dart';

class HomepageRemoteDataSource extends BaseApiService {
  Future<Map<String, dynamic>> getHomepage({
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
    final Map<String, dynamic> body = <String, dynamic>{
      'radius': radius,
      'page': page,
      'pageSize': pageSize,
    };

    if (address != null) body['address'] = address;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (q != null && q.isNotEmpty) body['q'] = q;
    if (categories != null && categories.isNotEmpty) {
      body['categories'] = categories;
    }
    if (homeCategories != null && homeCategories.isNotEmpty) {
      body['home_categories'] = homeCategories;
    }

    return await postRequest('/homepage', data: body);
  }
}
