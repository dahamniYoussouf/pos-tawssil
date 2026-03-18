import 'dart:typed_data';
import '../models/order.dart';
import '../models/restaurant_printer.dart';
import 'ticket_generator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice, BluetoothConnectionState, BluetoothCharacteristic;
import 'package:print_usb/print_usb.dart';
// Conditional import for dart:io (only on native platforms)
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;
import 'windows_raw_printer_stub.dart'
    if (dart.library.io) 'windows_raw_printer.dart' as winraw;

/// Service d'impression locale pour envoyer directement aux imprimantes réseau
/// Permet d'imprimer sans passer par le backend distant
class LocalPrintService {
  static String _describeWindowsStatusIssue(String code) {
    switch (code) {
      case 'OFFLINE':
        return '- Imprimante hors ligne';
      case 'PAPER_OUT':
        return '- Papier manquant';
      case 'PAPER_JAM':
        return '- Bourrage papier';
      case 'PAPER_PROBLEM':
        return '- Probleme papier';
      case 'DOOR_OPEN':
        return '- Capot ouvert';
      case 'NO_TONER':
        return '- Toner vide';
      case 'TONER_LOW':
        return '- Toner faible';
      case 'MANUAL_FEED':
        return '- Alimentation manuelle requise';
      case 'OUTPUT_BIN_FULL':
        return '- Bac de sortie plein';
      case 'USER_INTERVENTION':
        return '- Intervention utilisateur requise';
      case 'NOT_AVAILABLE':
        return '- Imprimante non disponible';
      case 'ERROR':
        return '- Erreur imprimante';
      case 'OUT_OF_MEMORY':
        return '- Memoire imprimante insuffisante';
      case 'PAUSED':
        return '- Imprimante en pause';
      case 'DRIVER_UPDATE_NEEDED':
        return '- Pilote a mettre a jour';
      case 'SERVER_UNKNOWN':
        return '- Serveur d impression inconnu';
    }
    return '- Probleme inconnu ($code)';
  }

  static void _throwIfWindowsPrinterStatusProblem(String printerName) {
    final statusFlags = winraw.WindowsRawPrinter.getPrinterStatusFlags(printerName);
    if (statusFlags == null) return;
    final issues = winraw.WindowsRawPrinter.describeStatusProblems(statusFlags);
    if (issues.isEmpty) return;

    final details = issues.map(_describeWindowsStatusIssue).join('\n');
    throw Exception(
      'Imprimante Windows "$printerName" non prete:\n'
      '$details\n\n'
      'Verifiez le papier, l etat de l imprimante et le pilote.',
    );
  }
  /// Normalise le type de connexion en tenant compte du champ ip.
  /// Permet de basculer en USB si l'ID commence par "USB:" même si
  /// connectionType est absent ou incorrect côté API.
  static String _resolveConnectionType(RestaurantPrinter printer) {
    final rawType = (printer.connectionType ?? '').toLowerCase().trim();
    final ip = printer.ip.trim();
    if (ip.toUpperCase().startsWith('USB:')) {
      return 'usb';
    }
    if (printer.bluetoothDeviceId != null || rawType == 'bluetooth') {
      return 'bluetooth';
    }
    return rawType.isEmpty ? 'network' : rawType;
  }
  /// Extrait l'IP réelle et le port depuis le champ ip qui peut être formaté
  /// Gère les formats: "192.168.1.10", "HTTP:http://192.168.1.10:80/print", etc.
  static Map<String, dynamic> extractIpAndPort(RestaurantPrinter printer) {
    String ip = printer.ip;
    int port = printer.port;
    
    // Si l'IP contient un préfixe de protocole (HTTP:, IPP:, LPD:, etc.)
    if (ip.contains('://') || ip.contains(':')) {
      // Essayer de parser comme URI
      try {
        // Enlever les préfixes de protocole (HTTP:, IPP:, LPD:, etc.)
        String cleanIp = ip.replaceFirst(RegExp(r'^[A-Z]+:'), '').trim();
        
        // Si ça commence par http:// ou https://, parser comme URI
        if (cleanIp.startsWith('http://') || cleanIp.startsWith('https://')) {
          final uri = Uri.parse(cleanIp);
          ip = uri.host;
          if (uri.hasPort) {
            port = uri.port;
          }
        } else if (cleanIp.contains(':')) {
          // Format simple IP:PORT
          final parts = cleanIp.split(':');
          if (parts.length >= 2) {
            ip = parts[0];
            final portStr = parts[1].split('/').first; // Enlever le chemin si présent
            port = int.tryParse(portStr) ?? printer.port;
          }
        }
      } catch (e) {
        print('[WARN] Error parsing IP format "$ip": $e, using as-is');
        // En cas d'erreur, essayer d'extraire juste l'IP
        final ipMatch = RegExp(r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b').firstMatch(ip);
        if (ipMatch != null) {
          ip = ipMatch.group(1)!;
        }
      }
    }
    
    return {'ip': ip, 'port': port};
  }

  /// Clé unique par périphérique physique (réseau, USB, Bluetooth) pour dédupliquer les impressions.
  static String deviceKeyFor(RestaurantPrinter p) {
    final ct = _resolveConnectionType(p);
    if (ct == 'usb' || ct == 'windows') {
      return p.ip.startsWith('USB:') ? p.ip : 'USB:${p.ip}';
    }
    if (ct == 'bluetooth') {
      return 'BT:${p.ip}';
    }
    final ipPort = extractIpAndPort(p);
    return '${ipPort['ip']}:${ipPort['port']}';
  }

  /// Vérifie si une imprimante est accessible localement sur le réseau
  /// Retourne true si l'imprimante répond sur le port spécifié
  /// Teste aussi les ports alternatifs si le port principal ne répond pas
  /// Retourne aussi des informations détaillées sur les ports disponibles
  static Future<Map<String, dynamic>> checkPrinterAccessibilityDetailed(
    RestaurantPrinter printer, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final ipPort = extractIpAndPort(printer);
    final ip = ipPort['ip'] as String;
    final port = ipPort['port'] as int;
    
    final errors = <String>[];
    bool configuredPortAccessible = false;
    bool port80Accessible = false;
    bool port9100Accessible = false;
    bool port9101Accessible = false;
    int recommendedPort = port;
    
    print('[INFO] Testing printer accessibility: $ip:$port');
    
    // Tester le port configuré
    if (!kIsWeb || port == 80 || port == 443) {
      try {
        if (kIsWeb && (port == 80 || port == 443)) {
          // En mode web, utiliser HTTP pour les ports 80/443
          try {
            final response = await http.get(
              Uri.parse('http://$ip:$port/'),
              headers: {'User-Agent': 'Tawsil-POS/1.0'},
            ).timeout(timeout);
            configuredPortAccessible = response.statusCode < 500;
            print('[OK] Printer $ip:$port is accessible (HTTP)');
          } catch (e) {
            configuredPortAccessible = false;
            print('[WARN] Port $port not accessible via HTTP: $e');
          }
        } else if (!kIsWeb) {
          // En mode natif, utiliser Socket
          final socket = await io.Socket.connect(ip, port, timeout: timeout).timeout(timeout);
          await socket.close();
          configuredPortAccessible = true;
          print('[OK] Printer $ip:$port is accessible');
        }
      } catch (e) {
        errors.add('Port $port: $e');
        print('[WARN] Port $port not accessible: $e');
      }
    } else {
      errors.add('Port $port: Non testable en mode web (utilisez le backend)');
      print('[WARN] Port $port ne peut pas être testé en mode web');
    }
    
    // TOUJOURS tester le port 80 (interface web) et le port 9100 (RAW) séparément
    // Car l'interface web peut fonctionner mais l'impression nécessite le port 9100
    
    // Test port 80 (HTTP - interface web)
    if (!kIsWeb) {
      try {
        final httpClient = io.HttpClient();
        final request = await httpClient.getUrl(Uri.parse('http://$ip:80/')).timeout(timeout);
        request.headers.set('User-Agent', 'Tawsil-POS/1.0');
        final response = await request.close().timeout(timeout);
        await response.drain();
        httpClient.close();
        port80Accessible = true;
        print('[OK] Port 80 (HTTP interface) is accessible');
      } catch (e) {
        print('[WARN] Port 80 (HTTP) not accessible: $e');
      }
    } else {
      // En mode web, utiliser http package
      try {
        final response = await http.get(
          Uri.parse('http://$ip:80/'),
          headers: {'User-Agent': 'Tawsil-POS/1.0'},
        ).timeout(timeout);
        port80Accessible = response.statusCode < 500;
        if (port80Accessible) {
          print('[OK] Port 80 (HTTP interface) is accessible');
        }
      } catch (e) {
        print('[WARN] Port 80 (HTTP) not accessible: $e');
      }
    }
    
    // Test port 9100 (RAW - impression)
    // En mode web, on ne peut pas tester les ports RAW directement
    if (!kIsWeb) {
      try {
        final socket9100 = await io.Socket.connect(ip, 9100, timeout: timeout).timeout(timeout);
        await socket9100.close();
        port9100Accessible = true;
        print('[OK] Port 9100 (RAW printing) is accessible');
        // Si le port configuré n'est pas accessible mais 9100 l'est, recommander 9100
        if (!configuredPortAccessible && port != 9100) {
          recommendedPort = 9100;
        }
      } catch (e) {
        errors.add('Port 9100: $e');
        print('[WARN] Port 9100 (RAW) not accessible: $e');
      }
      
      // Test port 9101 (RAW alternatif)
      try {
        final socket9101 = await io.Socket.connect(ip, 9101, timeout: timeout).timeout(timeout);
        await socket9101.close();
        port9101Accessible = true;
        print('[OK] Port 9101 (RAW alternative) is accessible');
        // Si ni le port configuré ni 9100 ne fonctionnent, recommander 9101
        if (!configuredPortAccessible && !port9100Accessible && port != 9101) {
          recommendedPort = 9101;
        }
      } catch (e) {
        print('[WARN] Port 9101 not accessible: $e');
      }
    } else {
      errors.add('Ports RAW (9100, 9101): Non testables en mode web - utilisez le backend');
      print('[WARN] Mode web: Les ports RAW ne peuvent pas être testés directement');
      print('[TIP] Utilisez le backend pour tester les ports RAW');
    }
    
    return {
      'ip': ip,
      'configuredPort': port,
      'configuredPortAccessible': configuredPortAccessible,
      'port80Accessible': port80Accessible,
      'port9100Accessible': port9100Accessible,
      'port9101Accessible': port9101Accessible,
      'recommendedPort': recommendedPort,
      'recommendedProtocol': 'raw',
      'errors': errors,
    };
  }
  
  /// Vérifie si une imprimante est accessible localement sur le réseau
  /// Retourne true si l'imprimante répond sur le port spécifié
  /// Teste aussi les ports alternatifs si le port principal ne répond pas
  static Future<bool> isPrinterAccessible(RestaurantPrinter printer, {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final results = await checkPrinterAccessibilityDetailed(printer, timeout: timeout);
      return results['configuredPortAccessible'] as bool || 
             results['port9100Accessible'] as bool ||
             results['port9101Accessible'] as bool;
    } catch (e) {
      final ipPort = extractIpAndPort(printer);
      print('[WARN] Printer ${printer.name} (${ipPort['ip']}:${ipPort['port']}) not accessible: $e');
      return false;
    }
  }

  /// Imprime une commande directement sur l'imprimante
  /// Supporte les connexions réseau (TCP/IP) et Bluetooth
  static Future<void> printOrderDirectly(
    RestaurantPrinter printer,
    Order order, {
    String? restaurantName,
    String? cashierName,
    String? cashierCode,
  }) async {
    final connectionType = _resolveConnectionType(printer);
    final isUsb = connectionType == 'usb' || connectionType == 'windows';

    if (connectionType == 'bluetooth') {
      print('[PRINT] Printing order #${order.orderNumber} to ${printer.name} via Bluetooth');
    } else if (isUsb) {
      print('[PRINT] Printing order #${order.orderNumber} to ${printer.name} via USB/Windows');
    } else {
      final ipPort = extractIpAndPort(printer);
      final ip = ipPort['ip'] as String;
      final port = ipPort['port'] as int;
      print('[PRINT] Printing order #${order.orderNumber} to ${printer.name} at $ip:$port');
    }
    
    // Vérifier l'accessibilité de l'imprimante (uniquement pour réseau)
    if (connectionType != 'bluetooth' && !isUsb) {
      final ipPort = extractIpAndPort(printer);
      final ip = ipPort['ip'] as String;
      final port = ipPort['port'] as int;
      
      final accessibilityResults = await checkPrinterAccessibilityDetailed(printer);
      final isAccessible = accessibilityResults['configuredPortAccessible'] as bool;
      final port80Accessible = accessibilityResults['port80Accessible'] as bool;
      final port9100Accessible = accessibilityResults['port9100Accessible'] as bool;
      final port9101Accessible = accessibilityResults['port9101Accessible'] as bool;
      final recommendedPort = accessibilityResults['recommendedPort'] as int;
      
      if (!isAccessible) {
        // Construire un message détaillé selon les ports accessibles
        String diagnostic = '';
        String solution = '';
        
        if (port80Accessible && !port9100Accessible && !port9101Accessible) {
        diagnostic = '[WARN] DIAGNOSTIC:\n'
                    '[OK] Interface web (port 80) accessible\n'
                    '[ERR] Port d\'impression (9100) non accessible\n\n'
                    'L\'interface web fonctionne, mais l\'impression ne peut pas se connecter.\n';
        solution = 'SOLUTION:\n'
                   '1. Vérifiez dans l\'interface web de l\'imprimante (http://$ip:80)\n'
                   '2. Cherchez les paramètres réseau ou d\'impression\n'
                   '3. Activez le port RAW (9100) pour l\'impression\n'
                   '4. Vérifiez que le firewall de l\'imprimante autorise le port 9100\n';
      } else if (port80Accessible && port9100Accessible) {
        diagnostic = '[OK] Interface web (port 80) accessible\n'
                    '[OK] Port d\'impression (9100) accessible\n\n';
        solution = 'SOLUTION:\n'
                   'Le port configuré ($port) ne fonctionne pas, mais le port 9100 est accessible.\n'
                   'Changez le port de l\'imprimante à 9100 dans la configuration.\n';
      } else if (port9100Accessible) {
        diagnostic = '[OK] Port d\'impression (9100) accessible\n';
        solution = 'SOLUTION:\n'
                   'Utilisez le port 9100 au lieu de $port pour l\'impression.\n';
      } else if (port9101Accessible) {
        diagnostic = '[OK] Port d\'impression alternatif (9101) accessible\n';
        solution = 'SOLUTION:\n'
                   'Utilisez le port 9101 au lieu de $port pour l\'impression.\n';
      } else {
        diagnostic = '[ERR] Aucun port d\'impression accessible\n';
        solution = 'SOLUTION:\n'
                   '1. Vérifiez que l\'imprimante est allumée\n'
                   '2. Vérifiez que l\'imprimante est sur le même réseau\n'
                   '3. Vérifiez les paramètres réseau de l\'imprimante\n';
      }
      
      throw Exception(
        'Imprimante ${printer.name} non accessible sur le port configuré.\n\n'
        'IP: $ip\n'
        'Port configuré: $port\n\n'
        '$diagnostic'
        '$solution'
        '\nDétails des tests:\n'
        '${port80Accessible ? "[OK]" : "[ERR]"} Port 80 (Interface web): ${port80Accessible ? "Accessible" : "Non accessible"}\n'
        '${port9100Accessible ? "[OK]" : "[ERR]"} Port 9100 (Impression RAW): ${port9100Accessible ? "Accessible" : "Non accessible"}\n'
        '${port9101Accessible ? "[OK]" : "[ERR]"} Port 9101 (RAW alternatif): ${port9101Accessible ? "Accessible" : "Non accessible"}\n\n'
        '[TIP] Port recommandé: $recommendedPort'
      );
      }
    }

    // Générer le contenu du ticket ESC/POS selon le type d'imprimante
    final ticketData = await TicketGenerator.generateTicketByType(
      type: printer.type,
      order: order,
      restaurantName: restaurantName ?? 'Restaurant',
      paperWidth: printer.paperWidthMm,
      cashierName: cashierName,
      cashierCode: cashierCode,
    );

    // Envoyer selon le type de connexion
    if (connectionType == 'bluetooth') {
      await _printViaBluetooth(printer, ticketData);
    } else if (isUsb) {
      await _printViaUsb(printer, ticketData);
    } else {
      final ipPort = extractIpAndPort(printer);
      await _printViaNetwork(
        printer,
        ticketData,
        ipPort['ip'] as String,
        ipPort['port'] as int,
      );
    }
  }

  /// Imprime via connexion réseau TCP/IP
  static Future<void> _printViaNetwork(
    RestaurantPrinter printer,
    Uint8List ticketData,
    String ip,
    int port,
  ) async {
    if (kIsWeb) {
      throw Exception('Impression réseau TCP/IP non disponible en mode web. Utilisez le backend ou lancez sur un appareil natif.');
    }
    
    io.Socket? socket;
    try {
      print('[INFO] Connecting to $ip:$port...');
      socket = await io.Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );

      print('[INFO] Sending ${ticketData.length} bytes to printer...');
      socket.add(ticketData);
      await socket.flush();
      
      print('[OK] Ticket envoyé avec succès à ${printer.name} ($ip:$port)');
    } catch (e) {
      print('[ERR] Erreur lors de l\'envoi à ${printer.name}: $e');
      
      String suggestions = '';
      if (e.toString().contains('Connection refused') || e.toString().contains('timed out')) {
        if (port == 80) {
          suggestions = '\n\n[TIP] Pour les imprimantes avec interface web (port 80), l\'impression se fait généralement sur le port 9100 (RAW).\n'
                       '   Essayez de modifier la configuration de l\'imprimante pour utiliser le port 9100.';
        } else if (port == 9100) {
          suggestions = '\n\n[TIP] Le port 9100 ne répond pas. Essayez:\n'
                       '   - Le port 9101 (alternative RAW)\n'
                       '   - Vérifier dans l\'interface web de l\'imprimante quel port est utilisé pour l\'impression RAW';
        }
      }
      
      throw Exception(
        'Erreur lors de l\'impression sur ${printer.name}:\n\n'
        'IP: $ip\n'
        'Port: $port\n'
        'Erreur: $e\n\n'
        'Vérifiez que:\n'
        '1. L\'imprimante est allumée et accessible\n'
        '2. Le port $port est ouvert sur l\'imprimante\n'
        '3. Le POS et l\'imprimante sont sur le même réseau\n'
        '4. Aucun firewall ne bloque la connexion\n'
        '5. Pour les imprimantes Ethernet avec interface web, utilisez généralement le port 9100 pour l\'impression ESC/POS'
        '$suggestions'
      );
    } finally {
      await socket?.close();
    }
  }

  /// Imprime via connexion Bluetooth
  static Future<void> _printViaBluetooth(
    RestaurantPrinter printer,
    Uint8List ticketData,
  ) async {
    if (kIsWeb) {
      throw Exception('Bluetooth non disponible en mode web');
    }

    if (printer.bluetoothDeviceId == null) {
      throw Exception('ID du périphérique Bluetooth manquant pour ${printer.name}');
    }

    BluetoothDevice? device;
    try {
      print('[INFO] Connexion Bluetooth à ${printer.name} (${printer.bluetoothDeviceId})...');
      
      // Créer le périphérique Bluetooth
      device = BluetoothDevice.fromId(printer.bluetoothDeviceId!);
      
      // Vérifier l'état actuel
      final currentState = await device.connectionState.first.timeout(
        const Duration(seconds: 2),
      );
      
      // Si déjà connecté, déconnecter d'abord
      if (currentState == BluetoothConnectionState.connected) {
        print('[INFO] Déjà connecté, déconnexion...');
        await device.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Se connecter
      print('[INFO] Connexion en cours...');
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
      
      // Attendre que la connexion soit établie
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));

      print('[OK] Connecté à ${printer.name} via Bluetooth');

      // Découvrir les services Bluetooth
      print('[INFO] Découverte des services Bluetooth...');
      final services = await device.discoverServices().timeout(
        const Duration(seconds: 10),
      );
      
      print('[INFO] ${services.length} service(s) trouvé(s)');
      
      // UUID du service Serial Port Profile (SPP) - standard pour les imprimantes
      const sppServiceUuid = '00001101-0000-1000-8000-00805F9B34FB';
      BluetoothCharacteristic? writeCharacteristic;
      
      // Chercher d'abord le service SPP (priorité)
      for (final service in services) {
        print('  Service: ${service.uuid}');
        
        // Si c'est le service SPP, utiliser sa première caractéristique d'écriture
        if (service.uuid.toString().toLowerCase() == sppServiceUuid.toLowerCase()) {
          print('  [OK] Service SPP trouvé!');
          for (final characteristic in service.characteristics) {
            print('    Caractéristique: ${characteristic.uuid} (write: ${characteristic.properties.write}, writeWithoutResponse: ${characteristic.properties.writeWithoutResponse})');
            if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
              writeCharacteristic = characteristic;
              print('    [OK] Caractéristique d\'écriture trouvée dans SPP');
              break;
            }
          }
          if (writeCharacteristic != null) break;
        }
      }
      
      // Si SPP non trouvé, chercher n'importe quelle caractéristique d'écriture
      if (writeCharacteristic == null) {
        print('[WARN] Service SPP non trouvé, recherche d\'une caractéristique d\'écriture...');
        for (final service in services) {
          for (final characteristic in service.characteristics) {
            if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
              writeCharacteristic = characteristic;
              print('  [OK] Caractéristique d\'écriture trouvée: ${characteristic.uuid}');
              break;
            }
          }
          if (writeCharacteristic != null) break;
        }
      }
      
      if (writeCharacteristic == null) {
        throw Exception(
          'Caractéristique d\'écriture Bluetooth non trouvée.\n'
          'Services disponibles: ${services.map((s) => s.uuid).join(", ")}\n'
          'L\'imprimante peut ne pas supporter le profil série Bluetooth (SPP).'
        );
      }

      // Envoyer les données par chunks si nécessaire (certaines imprimantes ont des limites)
      const maxChunkSize = 512; // Taille maximale par chunk
      final useWriteWithoutResponse = writeCharacteristic.properties.writeWithoutResponse;
      
      print('[INFO] Envoi de ${ticketData.length} bytes via Bluetooth...');
      
      if (ticketData.length <= maxChunkSize) {
        // Envoi direct si les données sont petites
        await writeCharacteristic.write(
          ticketData,
          withoutResponse: useWriteWithoutResponse,
        );
        print('[OK] Données envoyées en une fois');
      } else {
        // Envoi par chunks
        print('[INFO] Envoi par chunks de $maxChunkSize bytes...');
        int offset = 0;
        int chunkNumber = 0;
        
        while (offset < ticketData.length) {
          final chunkSize = (offset + maxChunkSize < ticketData.length)
              ? maxChunkSize
              : ticketData.length - offset;
          final chunk = ticketData.sublist(offset, offset + chunkSize);
          
          await writeCharacteristic.write(
            chunk,
            withoutResponse: useWriteWithoutResponse,
          );
          
          chunkNumber++;
          offset += chunkSize;
          
          // Petite pause entre les chunks pour éviter de surcharger
          if (offset < ticketData.length) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
        print('[OK] $chunkNumber chunk(s) envoyé(s)');
      }
      
      // Attendre un peu pour que les données soient transmises
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('[OK] Ticket envoyé avec succès à ${printer.name} via Bluetooth');
      
    } catch (e) {
      print('[ERR] Erreur lors de l\'impression Bluetooth: $e');
      throw Exception(
        'Erreur lors de l\'impression Bluetooth sur ${printer.name}:\n\n'
        'Périphérique: ${printer.bluetoothDeviceName ?? printer.bluetoothDeviceId}\n'
        'Erreur: $e\n\n'
        'Vérifiez que:\n'
        '1. Bluetooth est activé sur l\'appareil\n'
        '2. L\'imprimante est allumée et en mode appairage\n'
        '3. L\'imprimante est à portée (moins de 10 mètres)\n'
        '4. Les permissions Bluetooth sont accordées\n'
        '5. L\'imprimante est déjà appairée avec l\'appareil\n'
        '6. L\'imprimante supporte le profil série Bluetooth (SPP)'
      );
    } finally {
      // Toujours déconnecter
      try {
        if (device != null) {
          final currentState = await device.connectionState.first.timeout(
            const Duration(seconds: 1),
          );
          if (currentState == BluetoothConnectionState.connected) {
            print('[INFO] Déconnexion...');
            await device.disconnect();
          }
        }
      } catch (e) {
        print('[WARN] Erreur lors de la déconnexion: $e');
      }
    }
  }

  /// Imprime via connexion USB
  static Future<void> _printViaUsb(
    RestaurantPrinter printer,
    Uint8List ticketData,
  ) async {
    if (kIsWeb) {
      throw Exception('USB non disponible en mode web');
    }

    dynamic device;
    try {
      // L'ID peut être au format:
      // - USB:vendorId:productId (ex: USB:04f9:2042) - Format recommandé
      // - USB:deviceName (ex: USB:EPSON TM-T20) - Format fallback
      final deviceId = printer.ip.trim();
      if (deviceId.isEmpty) {
        throw Exception('Identifiant USB manquant pour ${printer.name}');
      }
      
      print('[INFO] Connexion USB à ${printer.name} (ID: $deviceId)...');

      // Sur Windows, permettre l'envoi direct vers un port USB/COM/LPT
      // Exemples d'ID acceptés: "USB:USB001", "USB:COM3", "USB:LPT1", "USB:\\.\USB001"
      if (io.Platform.isWindows) {
        final windowsPort = _extractWindowsPort(deviceId);
        String? printerName;
        if (deviceId.toUpperCase().startsWith('USB:')) {
          final candidate = deviceId.substring(4).trim();
          if (candidate.isNotEmpty &&
              _extractWindowsPort('USB:$candidate') == null) {
            printerName = candidate;
          }
        }
        printerName ??= printer.name.trim().isNotEmpty ? printer.name.trim() : null;

        String? portOwner;
        if (windowsPort != null) {
          portOwner = winraw.WindowsRawPrinter.findPrinterNameByPort(windowsPort);
          if (portOwner == null) {
            throw Exception(
              'Aucune imprimante Windows installee sur le port $windowsPort.\n'
              'Verifiez le port dans Windows et dans la configuration POS.',
            );
          }
          if (printerName != null && printerName.isNotEmpty &&
              portOwner.trim().toLowerCase() != printerName.trim().toLowerCase()) {
            throw Exception(
              'Port $windowsPort associe a "$portOwner", pas a "$printerName".\n'
              'Corrigez le port ou le nom de l\'imprimante.',
            );
          }
          _throwIfWindowsPrinterStatusProblem(portOwner);
        } else if (printerName != null && printerName.isNotEmpty) {
          final installedPort = winraw.WindowsRawPrinter.getPrinterPort(printerName);
          if (installedPort == null || installedPort.trim().isEmpty) {
            throw Exception(
              'Imprimante Windows introuvable ou pilote non installe:\n'
              '$printerName',
            );
          }
          _throwIfWindowsPrinterStatusProblem(printerName);
        }

        if (windowsPort != null) {
          try {
            await _printViaWindowsPort(
              windowsPort,
              ticketData,
              printerName: printer.name,
            );
            return;
          } catch (e) {
            // Fallback to Windows spooler if direct port write fails.
            print('[WARN] Direct port print failed ($windowsPort): $e');
          }
        }
        // Sinon, tenter l'impression via le nom d'imprimante Windows (spooler)
        if (printerName != null && printerName.isNotEmpty) {
          winraw.WindowsRawPrinter.printBytes(
            printerName,
            ticketData,
            jobName: 'Tawsil POS - ${printer.name}',
          );
          print('[OK] Ticket envoyé via imprimante Windows: $printerName');
          return;
        }
      }

      // Obtenir tous les périphériques USB
      final devices = await PrintUsb.getList();
      
      // Vérifier le format de l'ID
      if (deviceId.contains(':') && deviceId.split(':').length == 3) {
        // Format: USB:vendorId:productId (ex: USB:04f9:2042)
        final parts = deviceId.split(':');
        final vidHex = parts[1];
        final pidHex = parts[2];
        
        // Convertir en entiers pour comparaison
        final vid = int.tryParse(vidHex, radix: 16);
        final pid = int.tryParse(pidHex, radix: 16);
        
        if (vid != null && pid != null) {
          // Chercher par Vendor ID et Product ID (plus fiable)
          try {
            device = devices.firstWhere(
              (d) {
                try {
                  final dynamicD = d as dynamic;
                  return dynamicD.vendorId == vid && dynamicD.productId == pid;
                } catch (_) {
                  return false;
                }
              },
            );
            print('[OK] Périphérique USB trouvé par VID:PID ($vidHex:$pidHex): ${device.name}');
          } catch (_) {
            throw Exception('Périphérique USB non trouvé avec VID:$vidHex PID:$pidHex');
          }
        } else {
          throw Exception('Format VID:PID invalide dans $deviceId');
        }
      } else {
        // Format: USB:deviceName (fallback)
        final deviceName = deviceId.replaceFirst('USB:', '');
        device = devices.firstWhere(
          (d) => d.name == deviceName,
          orElse: () => throw Exception('Périphérique USB non trouvé: $deviceName'),
        );
        print('[OK] Périphérique USB trouvé par nom: ${device.name}');
      }

      // Se connecter au périphérique
      final connected = await PrintUsb.connect(name: device.name);
      if (!connected) {
        throw Exception('Impossible de se connecter à l\'imprimante USB');
      }
      
      print('[OK] Connecté à ${printer.name} via USB');

      // Envoyer les données par chunks si nécessaire
      const maxChunkSize = 512;
      
      print('[INFO] Envoi de ${ticketData.length} bytes via USB...');
      
      // Convertir Uint8List en List<int>
      final dataList = ticketData.toList();
      
      if (dataList.length <= maxChunkSize) {
        // Envoi direct si les données sont petites
        final success = await PrintUsb.printBytes(bytes: dataList, device: device);
        if (!success) {
          throw Exception('Échec de l\'envoi des données USB');
        }
        print('[OK] Données envoyées en une fois');
      } else {
        // Envoi par chunks
        print('[INFO] Envoi par chunks de $maxChunkSize bytes...');
        int offset = 0;
        int chunkNumber = 0;
        
        while (offset < dataList.length) {
          final chunkSize = (offset + maxChunkSize < dataList.length)
              ? maxChunkSize
              : dataList.length - offset;
          final chunk = dataList.sublist(offset, offset + chunkSize);
          
          final success = await PrintUsb.printBytes(bytes: chunk, device: device);
          if (!success) {
            throw Exception('Échec de l\'envoi du chunk $chunkNumber');
          }
          
          chunkNumber++;
          offset += chunkSize;
          
          // Petite pause entre les chunks
          if (offset < dataList.length) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
        print('[OK] $chunkNumber chunk(s) envoyé(s)');
      }
      
      // Attendre un peu pour que les données soient transmises
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('[OK] Ticket envoyé avec succès à ${printer.name} via USB');
      
    } catch (e) {
      print('[ERR] Erreur lors de l\'impression USB: $e');
      throw Exception(
        'Erreur lors de l\'impression USB sur ${printer.name}:\n\n'
        'Périphérique: ${printer.usbVendorName ?? printer.name}\n'
        'Erreur: $e\n\n'
        'Vérifiez que:\n'
        '1. L\'imprimante est branchée en USB\n'
        '2. Les pilotes USB de l\'imprimante sont installés\n'
        '3. L\'imprimante est allumée\n'
        '4. Aucune autre application n\'utilise l\'imprimante\n'
        '5. Les permissions USB sont accordées (Android)'
      );
    } finally {
      // print_usb n'expose pas de close() public; la connexion est gérée en interne
    }
  }

  /// Extrait un port Windows depuis un ID USB s'il est au format USB:PORT
  static String? _extractWindowsPort(String deviceId) {
    final normalized = deviceId.trim();
    if (!normalized.toUpperCase().startsWith('USB:')) return null;
    final raw = normalized.substring(4).trim();
    if (raw.isEmpty) return null;

    // Autoriser "PORT:USB001"
    final port = raw.toUpperCase().startsWith('PORT:')
        ? raw.substring(5).trim()
        : raw;

    if (port.startsWith(r'\\.\')) {
      return port;
    }

    final upper = port.toUpperCase();
    final isPort = RegExp(r'^(USB|COM|LPT)\d+$').hasMatch(upper);
    return isPort ? port : null;
  }

  /// Impression directe vers un port Windows (USB001/COMx/LPTx)
  static Future<void> _printViaWindowsPort(
    String port,
    Uint8List ticketData, {
    String? printerName,
  }) async {
    final target = port.startsWith(r'\\.\') ? port : r'\\.\' + port;
    print('[PRINT] Impression USB directe sur le port Windows: $target');
    try {
      final file = io.File(target);
      final raf = await file.open(mode: io.FileMode.write);
      await raf.writeFrom(ticketData);
      await raf.flush();
      await raf.close();
      print('[OK] Ticket envoyé via port Windows: ${printerName ?? target}');
    } catch (e) {
      throw Exception(
        'Erreur lors de l\'impression directe sur le port $port:\n$e\n\n'
        'Vérifiez que:\n'
        '1. Le port est correct (USB001/COMx/LPTx)\n'
        '2. L\'imprimante est installée sur ce port\n'
        '3. Aucun autre programme n\'utilise le port'
      );
    }
  }

  /// Imprime un ticket de test directement sur l'imprimante
  static Future<void> printTestTicketDirectly(
    RestaurantPrinter printer, {
    String? restaurantName,
  }) async {
    final connectionType = _resolveConnectionType(printer);
    final isUsb = connectionType == 'usb' || connectionType == 'windows';

    if (connectionType == 'bluetooth') {
      print('[PRINT] Printing test ticket to ${printer.name} via Bluetooth');
    } else if (isUsb) {
      print('[PRINT] Printing test ticket to ${printer.name} via USB');
    } else {
      print('[PRINT] Printing test ticket to ${printer.name} at ${printer.ip}:${printer.port}');
    }
    
    // Vérifier l'accessibilité de l'imprimante (uniquement pour réseau)
    if (connectionType != 'bluetooth' && !isUsb) {
      final isAccessible = await isPrinterAccessible(printer);
      if (!isAccessible) {
        throw Exception(
          'Imprimante ${printer.name} non accessible sur le réseau local.\n'
          'Vérifiez que l\'imprimante est allumée et connectée au même réseau WiFi.'
        );
      }
    }

    // Générer le ticket de test
    final testTicketData = await TicketGenerator.generateTestTicket(
      restaurantName: restaurantName ?? 'Restaurant',
      paperWidth: printer.paperWidthMm,
    );

    // Envoyer selon le type de connexion
    if (connectionType == 'bluetooth') {
      await _printViaBluetooth(printer, testTicketData);
    } else if (isUsb) {
      await _printViaUsb(printer, testTicketData);
    } else {
      final ipPort = extractIpAndPort(printer);
      await _printViaNetwork(
        printer,
        testTicketData,
        ipPort['ip'] as String,
        ipPort['port'] as int,
      );
    }
  }

  /// Ouvre le tiroir-caisse directement sur l'imprimante réseau locale
  static Future<void> openCashDrawerDirectly(RestaurantPrinter printer) async {
    if (kIsWeb) {
      throw Exception('Ouverture du tiroir-caisse non disponible en mode web. Utilisez le backend ou lancez sur un appareil natif.');
    }
    
    // Extraire l'IP et le port réels
    final ipPort = extractIpAndPort(printer);
    final ip = ipPort['ip'] as String;
    final port = ipPort['port'] as int;
    
    print('[TIP] Opening cash drawer on ${printer.name} at $ip:$port');
    
    // Vérifier l'accessibilité de l'imprimante
    final isAccessible = await isPrinterAccessible(printer);
    if (!isAccessible) {
      throw Exception(
        'Imprimante ${printer.name} non accessible sur le réseau local.\n'
        'Vérifiez que l\'imprimante est allumée et connectée au même réseau WiFi.'
      );
    }

    // Générer la commande ESC/POS pour ouvrir le tiroir
    final drawerCmd = await TicketGenerator.generateCashDrawerCommand();

    // Envoyer la commande à l'imprimante via TCP/IP
    io.Socket? socket;
    try {
      socket = await io.Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );

      socket.add(drawerCmd);
      await socket.flush();
      
      print('[OK] Tiroir-caisse ouvert avec succès sur ${printer.name} ($ip:$port)');
    } catch (e) {
      print('[ERR] Erreur lors de l\'ouverture du tiroir sur ${printer.name}: $e');
      throw Exception(
        'Erreur lors de l\'ouverture du tiroir sur ${printer.name}:\n$e'
      );
    } finally {
      await socket?.close();
    }
  }
}












