import 'package:delivery_app/src/core/services/base_api_service.dart';

class DriverService extends BaseApiService {
  Future<Map<String, dynamic>> fetchDriverProfile() async {
    return await getRequest('/driver/profile/me');
  }
}
