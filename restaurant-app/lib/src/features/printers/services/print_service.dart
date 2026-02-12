import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import '../models/restaurant_printer.dart';
import 'local_print_service.dart';
import 'printer_storage_service.dart';

class PrintService {
  final PrinterStorageService _storage = PrinterStorageService();

  Future<List<RestaurantPrinter>> loadPrinters() async {
    return _storage.loadPrinters();
  }

  Future<void> printOrder(
    OrderModel order, {
    Function(String)? onError,
  }) async {
    final printers = await _storage.loadPrinters();
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
}
