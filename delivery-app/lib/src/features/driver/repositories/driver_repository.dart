import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:delivery_app/src/features/driver/services/driver_service.dart';

class DriverRepository {
  final DriverService _driverService;

  DriverRepository({DriverService? driverService}) : _driverService = driverService ?? DriverService();

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
}
