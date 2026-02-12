import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;

class LocalPrinterScanner {
  static Future<String?> getLocalNetworkBase() async {
    if (kIsWeb) return null;

    try {
      var interfaces = await io.NetworkInterface.list(
        includeLinkLocal: false,
        type: io.InternetAddressType.IPv4,
      );

      if (interfaces.isEmpty) {
        interfaces = await io.NetworkInterface.list(
          includeLinkLocal: true,
          type: io.InternetAddressType.IPv4,
        );
      }

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.isLoopback) continue;
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            return '${parts[0]}.${parts[1]}.${parts[2]}';
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> checkPrinterAtIP(
    String ip,
    int port, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (kIsWeb) return false;
    try {
      final socket = await io.Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> testSpecificIP(
    String ip, {
    List<int>? ports,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final results = <Map<String, dynamic>>[];
    final portsToTest = ports ?? [9100, 9101, 631, 515, 80];

    for (final port in portsToTest) {
      final ok = await checkPrinterAtIP(ip, port, timeout: timeout);
      if (ok) {
        results.add({
          'ip': ip,
          'port': port,
        });
      }
    }

    return results;
  }

  static Future<List<Map<String, dynamic>>> scanNetworkForPrinters({
    String? networkBase,
    int startHost = 1,
    int endHost = 254,
    List<int>? ports,
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final detected = <Map<String, dynamic>>[];
    final base = networkBase ?? await getLocalNetworkBase();
    if (base == null) return detected;

    final portsToScan = ports ?? [9100];
    const maxConcurrent = 30;
    final pending = <Future<void>>[];
    int active = 0;

    Future<void> schedule(String ip, int port) async {
      active++;
      final ok = await checkPrinterAtIP(ip, port, timeout: timeout);
      if (ok) {
        detected.add({'ip': ip, 'port': port});
      }
      active--;
    }

    for (int host = startHost; host <= endHost; host++) {
      final ip = '$base.$host';
      for (final port in portsToScan) {
        while (active >= maxConcurrent) {
          await Future.delayed(const Duration(milliseconds: 25));
        }
        pending.add(schedule(ip, port));
      }
    }

    await Future.wait(pending);
    return detected;
  }

  static Future<List<Map<String, dynamic>>> quickScan({
    String? networkBase,
    int startHost = 1,
    int endHost = 254,
  }) async {
    return scanNetworkForPrinters(
      networkBase: networkBase,
      startHost: startHost,
      endHost: endHost,
      ports: [9100],
      timeout: const Duration(seconds: 1),
    );
  }
}
