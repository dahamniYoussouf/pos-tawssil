import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import '../models/order.dart';

class PrintService {
  // Configuration de l'imprimante (IP locale)
  static const String printerIp = '192.168.1.100';
  static const PaperSize paperSize = PaperSize.mm80;

  Future<void> printOrder(Order order) async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paperSize, profile);

      final PosPrintResult connect = await printer.connect(
        printerIp,
        port: 9100,
        timeout: Duration(seconds: 5),
      );

      if (connect == PosPrintResult.success) {
        _buildTicket(printer, order);
        printer.cut();
        printer.disconnect();
      }
    } catch (e) {
      throw Exception('Erreur d\'impression: ${e.toString()}');
    }
  }

  void _buildTicket(NetworkPrinter printer, Order order) {
    // Header
    printer.text(
      'RESTAURANT TAWSIL',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    printer.emptyLines(1);

    // Order info
    printer.text('Commande #${order.orderNumber}');
    printer.text('Caissier: ${order.cashierId}');
    printer.text('Date: ${order.createdAt.toString()}');
    printer.hr();

    // Items
    for (var item in order.items) {
      printer.row([
        PosColumn(
          text: item.menuItemName,
          width: 6,
        ),
        PosColumn(
          text: 'x${item.quantite}',
          width: 2,
        ),
        PosColumn(
          text: '${item.prixTotal.toStringAsFixed(2)} DA',
          width: 4,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
      
      if (item.instructionsSpeciales != null) {
        printer.text(
          '  Note: ${item.instructionsSpeciales}',
          styles: PosStyles(fontType: PosFontType.fontB),
        );
      }
    }

    printer.hr();

    // Total
    printer.row([
      PosColumn(text: 'TOTAL', width: 8),
      PosColumn(
        text: '${order.totalAmount.toStringAsFixed(2)} DA',
        width: 4,
        styles: PosStyles(
          align: PosAlign.right,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);

    printer.emptyLines(1);
    printer.text(
      'Merci de votre visite!',
      styles: PosStyles(align: PosAlign.center),
    );
    printer.emptyLines(2);
  }

  // Ouvrir le tiroir-caisse
  Future<void> openCashDrawer() async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paperSize, profile);

      final connect = await printer.connect(printerIp, port: 9100);
      
      if (connect == PosPrintResult.success) {
        printer.drawer(); // Commande d'ouverture du tiroir
        printer.disconnect();
      }
    } catch (e) {
      throw Exception('Erreur ouverture tiroir: ${e.toString()}');
    }
  }
}