import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show FlutterBluePlus, BluetoothDevice, BluetoothAdapterState, BluetoothConnectionState, ScanResult;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service de scan Bluetooth pour détecter les imprimantes Bluetooth
/// Fonctionne sur Android, iOS, Windows, macOS, Linux
/// ⚠️ Non disponible en mode web
class BluetoothPrinterScanner {
  /// Vérifie si Bluetooth est disponible sur l'appareil
  static Future<bool> isBluetoothAvailable() async {
    if (kIsWeb) {
      print('⚠️ Bluetooth non disponible en mode web');
      return false;
    }

    try {
      final adapterState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
      );
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('❌ Erreur lors de la vérification Bluetooth: $e');
      return false;
    }
  }

  /// Demande les permissions Bluetooth (Android)
  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return false;
    }

    try {
      // Vérifier l'état actuel
      final adapterState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
      );

      if (adapterState == BluetoothAdapterState.on) {
        return true;
      }

      // Essayer d'activer Bluetooth
      await FlutterBluePlus.turnOn();
      
      // Attendre que Bluetooth soit activé
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));

      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'activation Bluetooth: $e');
      return false;
    }
  }

  /// Scanne les périphériques Bluetooth à proximité
  /// Retourne une liste d'imprimantes potentielles (périphériques avec noms contenant "printer", "pos", "esc", etc.)
  static Future<List<Map<String, dynamic>>> scanForPrinters({
    Duration scanDuration = const Duration(seconds: 10),
  }) async {
    if (kIsWeb) {
      print('⚠️ Scan Bluetooth non disponible en mode web');
      return [];
    }

    final List<Map<String, dynamic>> detectedPrinters = [];
    StreamSubscription<List<ScanResult>>? scanSubscription;

    try {
      // Vérifier que Bluetooth est disponible (la demande de permission est gérée côté UI)
      final isAvailable = await isBluetoothAvailable();
      if (!isAvailable) {
        throw Exception(
          'Bluetooth non disponible. Veuillez activer Bluetooth dans les paramètres de l\'appareil.'
        );
      }

      print('🔍 Démarrage du scan Bluetooth...');
      
      // Mots-clés pour identifier les imprimantes
      final printerKeywords = [
        'printer',
        'imprimante',
        'pos',
        'esc',
        'epson',
        'xprinter',
        'star',
        'citizen',
        'bixolon',
        'receipt',
        'thermal',
      ];

      // Démarrer le scan
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: false,
      );

      // Écouter les résultats du scan
      final foundDevices = <String, ScanResult>{};

      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.device.remoteId.toString();

          // Vérifier si le nom contient des mots-clés d'imprimante
          final nameLower = deviceName.toLowerCase();
          final isPrinter = printerKeywords.any(
            (keyword) => nameLower.contains(keyword.toLowerCase()),
          );

          // Stocker le périphérique s'il semble être une imprimante
          if (isPrinter || result.rssi > -80) {
            // Filtrer les doublons
            if (!foundDevices.containsKey(result.device.remoteId.toString())) {
              foundDevices[result.device.remoteId.toString()] = result;
              
              print('📱 Périphérique trouvé: $deviceName (RSSI: ${result.rssi})');
            }
          }
        }
      });

      // Attendre la fin du scan
      await Future.delayed(scanDuration);

      // Arrêter le scan
      await FlutterBluePlus.stopScan();

      // Convertir les résultats en format standardisé
      for (final result in foundDevices.values) {
        final deviceName = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.device.remoteId.toString();

        detectedPrinters.add({
          'found': true,
          'ip': result.device.remoteId.toString(), // Utiliser l'ID comme "adresse"
          'port': 0, // Non utilisé pour Bluetooth
          'name': deviceName,
          'deviceId': result.device.remoteId.toString(),
          'deviceName': deviceName,
          'rssi': result.rssi,
          'protocol': 'bluetooth',
          'connectionType': 'bluetooth',
          'type': 'network',
          'confidence': 'medium',
          'suggestedConfig': {
            'ip': result.device.remoteId.toString(),
            'port': 0,
            'name': deviceName,
            'connection_type': 'bluetooth',
            'bluetooth_device_id': result.device.remoteId.toString(),
            'bluetooth_device_name': deviceName,
            'type': 'general',
            'is_enabled': true,
            'paper_width_mm': 80,
          },
        });
      }

      print('✅ Scan Bluetooth terminé: ${detectedPrinters.length} imprimante(s) trouvée(s)');
      return detectedPrinters;
    } catch (e) {
      print('❌ Erreur lors du scan Bluetooth: $e');
      await FlutterBluePlus.stopScan();
      rethrow;
    } finally {
      await scanSubscription?.cancel();
    }
  }

  /// Teste la connexion à un périphérique Bluetooth spécifique
  static Future<bool> testBluetoothConnection(String deviceId) async {
    if (kIsWeb) {
      return false;
    }

    try {
      print('🔍 Test de connexion Bluetooth: $deviceId');
      
      // Trouver le périphérique
      final device = BluetoothDevice.fromId(deviceId);
      
      // Vérifier l'état actuel de connexion
      final currentState = await device.connectionState.first.timeout(
        const Duration(seconds: 2),
      );
      
      // Si déjà connecté, déconnecter d'abord pour tester
      if (currentState == BluetoothConnectionState.connected) {
        await device.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Essayer de se connecter
      await device.connect(
        timeout: const Duration(seconds: 5),
        autoConnect: false,
      );

      // Attendre que la connexion soit établie
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 5));

      // Vérifier que la connexion est bien établie
      final finalState = await device.connectionState.first.timeout(
        const Duration(seconds: 1),
      );

      if (finalState == BluetoothConnectionState.connected) {
        // Déconnecter après le test
        await device.disconnect();
        print('✅ Connexion Bluetooth réussie');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Erreur lors du test Bluetooth: $e');
      // Essayer de déconnecter en cas d'erreur
      try {
        final device = BluetoothDevice.fromId(deviceId);
        await device.disconnect();
      } catch (_) {
        // Ignorer les erreurs de déconnexion
      }
      return false;
    }
  }
}
