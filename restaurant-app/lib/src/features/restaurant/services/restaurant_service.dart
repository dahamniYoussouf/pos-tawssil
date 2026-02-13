import 'dart:io';
import 'package:restaurant_app/src/core/services/base_api_service.dart';

class RestaurantService extends BaseApiService {
  Future<Map<String, dynamic>> getRestaurantProfile() async {
    return await getRequest('/restaurant/profile/me');
  }

  Future<Map<String, dynamic>> getRestaurantDetails() async {
    return await getRequest('/restaurant/details');
  }

  Future<Map<String, dynamic>> updateRestaurantProfile(
      String id, Map<String, dynamic> data) async {
    return await putRequest('/restaurant/update/$id', data: data);
  }

  Future<Map<String, dynamic>> updateRestaurantImage(String path) async {
    return await uploadMultipartFile('/uploads/upload',
        file: File(path), fileFieldName: 'image');
  }

  Future<Map<String, dynamic>> patchRestaurantStatus(String status,
      {String? note}) async {
    final Map<String, dynamic> data = {
      'availability_status': status,
    };
    if (note != null) {
      data['availability_note'] = note;
    }
    return await patchRequest('/restaurant/status', data: data);
  }
}
