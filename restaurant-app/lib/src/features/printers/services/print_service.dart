import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import '../models/restaurant_printer.dart';
import 'local_print_service.dart';
import 'printer_api_service.dart';

class PrintService {
  final PrinterApiService _printerApi = PrinterApiService();

  Future<List<RestaurantPrinter>> loadPrinters() async {
    return _printerApi.fetchPrinters();
  }

  Future<void> printOrder(
    OrderModel order, {
    Function(String)? onError,
  }) async {
    List<RestaurantPrinter> printers = [];
    try {
      printers = await _printerApi.fetchPrinters();
    } catch (e) {
      if (onError != null) {
        onError('Failed to load printers: ${_errorMessage(e)}');
      }
      return;
    }
    final enabledPrinters = printers.where((p) => p.isEnabled).toList();

    if (enabledPrinters.isEmpty) {
      if (onError != null) {
        onError('No printer configured.');
      }
      return;
    }

    for (final printer in enabledPrinters) {
      try {
        await LocalPrintService.printOrderDirectly(
          printer,
          order,
          restaurantName: order.restaurantName,
        );
      } catch (e) {
        if (onError != null) {
          onError('Print failed on ${printer.name}: $e');
        }
      }
    }
  }

  Future<void> printTestTicket(RestaurantPrinter printer) async {
    await LocalPrintService.printTestTicketDirectly(printer);
  }

  String _errorMessage(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }
}
