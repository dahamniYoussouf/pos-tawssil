import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:delivery_app/src/features/driver/services/driver_service.dart';

class DriverRepository {
  final DriverService _driverService;

  DriverRepository({DriverService? driverService})
      : _driverService = driverService ?? DriverService();

  Future<Either<String, DriverModel>> fetchDriverProfile() async {
    try {
      final response = await _driverService.fetchDriverProfile();
      if (response['success'] == true) {
        final data = response['data'] ?? response['profile'] ?? response;
        if (data is Map<String, dynamic>) {
          final driver = DriverModel.fromJson(data);
          return Right(driver);
        }
        return const Left('Invalid response format');
      } else {
        return Left(response['message'] ?? 'Failed to fetch driver profile');
      }
    } catch (e) {
      return Left('Error fetching driver profile: ${e.toString()}');
    }
  }

  Future<Either<String, void>> updateGPS(
      String driverId, double lat, double lng) async {
    try {
      final response = await _driverService.updateGPS(driverId, lat, lng);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to update GPS');
      }
    } catch (e) {
      return Left('Error updating GPS: ${e.toString()}');
    }
  }

  Future<Either<String, void>> updateStatus(String status) async {
    try {
      final response = await _driverService.updateStatus(status);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      return Left('Error updating status: ${e.toString()}');
    }
  }
}
