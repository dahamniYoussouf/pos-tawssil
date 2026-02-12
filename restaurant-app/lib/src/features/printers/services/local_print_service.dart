import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import '../models/restaurant_printer.dart';
import 'ticket_generator.dart';
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;

class LocalPrintService {
  static Map<String, dynamic> extractIpAndPort(RestaurantPrinter printer) {
    String ip = printer.ip.trim();
    int port = printer.port;

    if (ip.contains('://') || ip.contains(':')) {
      try {
        String cleanIp = ip.replaceFirst(RegExp(r'^[A-Z]+:'), '').trim();
        if (cleanIp.startsWith('http://') || cleanIp.startsWith('https://')) {
          final uri = Uri.parse(cleanIp);
          ip = uri.host;
          if (uri.hasPort) {
            port = uri.port;
          }
        } else if (cleanIp.contains(':')) {
          final parts = cleanIp.split(':');
          if (parts.length >= 2) {
            ip = parts[0];
            final portStr = parts[1].split('/').first;
            port = int.tryParse(portStr) ?? printer.port;
          }
        }
      } catch (_) {
        final ipMatch =
            RegExp(r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b')
                .firstMatch(ip);
        if (ipMatch != null) {
          ip = ipMatch.group(1)!;
        }
      }
    }

    return {'ip': ip, 'port': port};
  }

  static Future<bool> isPrinterAccessible(
    RestaurantPrinter printer, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (kIsWeb) return false;
    final ipPort = extractIpAndPort(printer);
    final ip = ipPort['ip'] as String;
    final port = ipPort['port'] as int;
    try {
      final socket = await io.Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> printOrderDirectly(
    RestaurantPrinter printer,
    OrderModel order, {
    String? restaurantName,
  }) async {
    final ticketData = await TicketGenerator.generateTicket(
      order: order,
      restaurantName: restaurantName ?? order.restaurantName ?? 'Restaurant',
      paperWidth: printer.paperWidthMm,
    );

    final ipPort = extractIpAndPort(printer);
    await _printViaNetwork(
      printer,
      ticketData,
      ipPort['ip'] as String,
      ipPort['port'] as int,
    );
  }

  static Future<void> printTestTicketDirectly(
    RestaurantPrinter printer, {
    String? restaurantName,
  }) async {
    final ticketData = await TicketGenerator.generateTestTicket(
      restaurantName: restaurantName ?? 'Restaurant',
      paperWidth: printer.paperWidthMm,
    );

    final ipPort = extractIpAndPort(printer);
    await _printViaNetwork(
      printer,
      ticketData,
      ipPort['ip'] as String,
      ipPort['port'] as int,
    );
  }

  static Future<void> _printViaNetwork(
    RestaurantPrinter printer,
    Uint8List ticketData,
    String ip,
    int port,
  ) async {
    if (kIsWeb) {
      throw Exception(
        'Network printing is not available on web. Use a native device.',
      );
    }

    io.Socket? socket;
    try {
      socket = await io.Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(ticketData);
      await socket.flush();
    } catch (e) {
      throw Exception(
        'Failed to print on ${printer.name} at $ip:$port\n$e',
      );
    } finally {
      await socket?.close();
    }
  }
}
