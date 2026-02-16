import 'package:delivery_app/src/core/services/base_api_service.dart';

class DriverService extends BaseApiService {
  Future<Map<String, dynamic>> fetchDriverProfile() async {
    return await getRequest('/driver/profile/me');
  }

  Future<Map<String, dynamic>> updateGPS(
      String driverId, double lat, double lng) async {
    return await putRequest(
      '/order/drivers/$driverId/gps',
      data: {
        'latitude': lat,
        'longitude': lng,
      },
    );
  }
}
