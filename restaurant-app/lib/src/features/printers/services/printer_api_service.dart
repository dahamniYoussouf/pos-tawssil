import 'package:restaurant_app/src/core/services/base_api_service.dart';
import '../models/restaurant_printer.dart';

class PrinterApiService extends BaseApiService {
  Future<List<RestaurantPrinter>> fetchPrinters() async {
    final response = await getRequest('/restaurant/printers');
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => RestaurantPrinter.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      return [];
    }
    throw Exception(response['message'] ?? 'Failed to fetch printers');
  }

  Future<RestaurantPrinter> createPrinter({
    required String name,
    required String type,
    required String ip,
    required int port,
    required bool isEnabled,
    required int paperWidthMm,
  }) async {
    final response = await postRequest(
      '/restaurant/printers',
      data: {
        'name': name,
        'type': type,
        'ip': ip,
        'port': port,
        'is_enabled': isEnabled,
        'paper_width_mm': paperWidthMm,
      },
    );

    if (response['success'] == true && response['data'] is Map) {
      return RestaurantPrinter.fromMap(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    throw Exception(response['message'] ?? 'Failed to create printer');
  }

  Future<RestaurantPrinter> updatePrinter({
    required String printerId,
    required String name,
    required String type,
    required String ip,
    required int port,
    required bool isEnabled,
    required int paperWidthMm,
  }) async {
    final response = await putRequest(
      '/restaurant/printers/$printerId',
      data: {
        'name': name,
        'type': type,
        'ip': ip,
        'port': port,
        'is_enabled': isEnabled,
        'paper_width_mm': paperWidthMm,
      },
    );

    if (response['success'] == true && response['data'] is Map) {
      return RestaurantPrinter.fromMap(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    throw Exception(response['message'] ?? 'Failed to update printer');
  }

  Future<void> deletePrinter(String printerId) async {
    final response = await deleteRequest('/restaurant/printers/$printerId');
    if (response['success'] == true) {
      return;
    }
    throw Exception(response['message'] ?? 'Failed to delete printer');
  }
}
