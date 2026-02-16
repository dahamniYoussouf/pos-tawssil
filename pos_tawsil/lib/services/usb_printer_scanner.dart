import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:print_usb/print_usb.dart';
// Conditional import for dart:io (only on native platforms)
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;
import 'windows_raw_printer_stub.dart'
    if (dart.library.io) 'windows_raw_printer.dart' as winraw;

/// Service de scan USB pour détecter les imprimantes USB
/// Fonctionne sur Windows
/// ⚠️ Non disponible en mode web
class UsbPrinterScanner {
  /// Vérifie si USB est disponible sur l'appareil
  static Future<bool> isUsbAvailable() async {
    if (kIsWeb) {
      print('⚠️ USB non disponible en mode web');
      return false;
    }
    if (!io.Platform.isWindows) {
      print('⚠️ USB disponible uniquement sur Windows dans cette version');
      return false;
    }

    try {
      // Vérifier si le service est disponible
      final devices = await PrintUsb.getList();
      print('✅ USB disponible: ${devices.length} périphérique(s) trouvé(s)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification USB: $e');
      print('💡 Vérifiez que:');
      print('   1. Le plugin print_usb est installé');
      print('   2. Les dépendances natives sont compilées');
      print('   3. Vous n\'êtes pas en mode web');
      return false;
    }
  }

  /// Liste tous les périphériques USB (pour diagnostic)
  static Future<List<String>> listAllUsbDevices() async {
    if (kIsWeb) {
      return [];
    }
    if (!io.Platform.isWindows) {
      print('⚠️ USB disponible uniquement sur Windows dans cette version');
      return [];
    }

    try {
      final devices = await PrintUsb.getList();
      return devices.map((d) => d.name ?? 'Périphérique sans nom').toList();
    } catch (e) {
      print('❌ Erreur lors de la liste USB: $e');
      return [];
    }
  }

  /// Scanne les imprimantes USB disponibles
  /// Retourne une liste d'imprimantes USB détectées
  /// Détecte automatiquement TOUS les périphériques USB et les classe selon leur probabilité d'être une imprimante
  static Future<List<Map<String, dynamic>>> scanForPrinters({
    Duration scanDuration = const Duration(seconds: 5),
    bool showAllDevices = true, // Par défaut, affiche tous les périphériques USB pour permettre la sélection manuelle
  }) async {
    if (kIsWeb) {
      print('⚠️ Scan USB non disponible en mode web');
      return [];
    }
    if (!io.Platform.isWindows) {
      print('⚠️ USB disponible uniquement sur Windows dans cette version');
      return [];
    }

    final List<Map<String, dynamic>> detectedPrinters = [];
    final List<Map<String, dynamic>> allDevices = [];
    final Set<String> seenDeviceIds = {};

    try {
      print('🔍 Démarrage du scan USB...');
      
      // Obtenir la liste des périphériques USB
      final devices = await PrintUsb.getList();
      
      print('📱 ${devices.length} périphérique(s) USB trouvé(s)');

      // Mots-clés étendus pour identifier les imprimantes
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
        'xp-80',
        'xp80',
        'tm-',
        'tm ',
        'rp-',
        'rp ',
        'impact',
        'zebra',
        'brother',
        'hp ',
        'canon',
        'lexmark',
        'okidata',
        'dymo',
        'label',
        'ticket',
        'roll',
        'dot matrix',
        'inkjet',
        'laser',
        'print',
      ];

      for (final device in devices) {
        final deviceName = device.name?.toLowerCase() ?? '';
        final displayName = device.name ?? 'Périphérique USB inconnu';
        
        // Récupérer les propriétés du périphérique (si disponibles)
        // Le plugin print_usb peut exposer: name, vendorId, productId, manufacturer, etc.
        // Note: We use dynamic access since print_usb may have different properties across versions
        dynamic vendorId;
        dynamic productId;
        dynamic manufacturer;
        
        try {
          // Essayer d'accéder aux propriétés si elles existent via dynamic cast
          final dynamicDevice = device as dynamic;
          try { vendorId = dynamicDevice.vendorId; } catch (_) {}
          try { productId = dynamicDevice.productId; } catch (_) {}
          try { manufacturer = dynamicDevice.manufacturer; } catch (_) {}
        } catch (_) {
          // Les propriétés peuvent ne pas être disponibles selon la version du plugin
        }
        
        // Enregistrer tous les périphériques pour debug avec toutes les infos disponibles
        final deviceInfo = {
          'name': displayName,
          'rawName': device.name,
        };
        if (vendorId != null) deviceInfo['vendorId'] = vendorId;
        if (productId != null) deviceInfo['productId'] = productId;
        if (manufacturer != null) deviceInfo['manufacturer'] = manufacturer;
        allDevices.add(deviceInfo);
        
        // Afficher les informations du périphérique pour diagnostic
        String deviceInfoStr = displayName;
        if (vendorId != null && productId != null) {
          final vidHex = vendorId is int ? vendorId.toRadixString(16).padLeft(4, '0') : vendorId.toString();
          final pidHex = productId is int ? productId.toRadixString(16).padLeft(4, '0') : productId.toString();
          deviceInfoStr += ' (VID: $vidHex, PID: $pidHex)';
        }
        print('  📱 Périphérique USB trouvé: $deviceInfoStr');

        // Vérifier si c'est une imprimante potentielle
        final isPrinter = printerKeywords.any(
          (keyword) => deviceName.contains(keyword),
        );

        // Calculer un score de confiance pour déterminer si c'est probablement une imprimante
        int confidenceScore = 0;
        if (isPrinter) {
          confidenceScore = 100; // Identifié comme imprimante
        } else {
          // Vérifier d'autres indices
          // Vérifier si c'est dans la classe USB "Printer" (si disponible)
          try {
            // Certains périphériques peuvent avoir une propriété deviceClass
            final dynamicDevice = device as dynamic;
            final deviceClass = dynamicDevice.deviceClass;
            if (deviceClass != null) {
              final deviceClassStr = deviceClass.toString().toLowerCase();
              if (deviceClassStr.contains('printer') || deviceClassStr.contains('print')) {
                confidenceScore = 80;
              }
            }
          } catch (_) {
            // Propriété non disponible
          }
          
          // Vérifier le manufacturer pour des indices
          if (manufacturer != null) {
            final manufacturerLower = manufacturer.toString().toLowerCase();
            final knownPrinterManufacturers = [
              'epson', 'hp', 'canon', 'brother', 'lexmark', 'xerox',
              'samsung', 'ricoh', 'konica', 'minolta', 'oki', 'citizen',
              'star', 'bixolon', 'xprinter', 'zebra', 'dymo', 'rollo'
            ];
            if (knownPrinterManufacturers.any((m) => manufacturerLower.contains(m))) {
              confidenceScore = confidenceScore > 60 ? confidenceScore : 60;
            }
          }
        }

        // TOUJOURS afficher tous les périphériques si showAllDevices est true (par défaut)
        // Cela permet à l'utilisateur de sélectionner manuellement même les périphériques non identifiés
        if (showAllDevices || isPrinter) {
          // Générer l'ID du périphérique
          // PRIORITÉ 1: Utiliser Vendor ID + Product ID si disponibles (plus fiable et unique)
          // PRIORITÉ 2: Utiliser le nom du périphérique (peut changer selon Windows)
          String deviceId;
          if (vendorId != null && productId != null) {
            final vidHex = vendorId is int ? vendorId.toRadixString(16).padLeft(4, '0') : vendorId.toString();
            final pidHex = productId is int ? productId.toRadixString(16).padLeft(4, '0') : productId.toString();
            deviceId = 'USB:$vidHex:$pidHex';
            print('  ✅ Utilisation VID:PID pour l\'ID: $deviceId');
          } else {
            // Fallback: utiliser le nom (moins fiable car peut changer)
            deviceId = 'USB:${device.name ?? 'Unknown'}';
            print('  ⚠️ Utilisation du nom pour l\'ID (moins fiable): $deviceId');
          }
          
          // Déterminer le niveau de confiance
          String confidence;
          if (confidenceScore >= 80) {
            confidence = 'high';
          } else if (confidenceScore >= 50) {
            confidence = 'medium';
          } else {
            confidence = 'low';
          }
          
          detectedPrinters.add({
            'found': true,
            'ip': deviceId, // Format: USB:vendorId:productId ou USB:deviceName
            'port': 0, // Non utilisé pour USB
            'name': displayName,
            'deviceId': deviceId,
            'deviceName': displayName,
            'vendorId': vendorId,
            'productId': productId,
            'manufacturer': manufacturer,
            'protocol': 'usb',
            'connectionType': 'usb',
            'type': 'network',
            'confidence': confidence,
            'confidenceScore': confidenceScore, // Score numérique pour tri
            'isPrinter': isPrinter, // Indique si identifié comme imprimante
            'autoDetected': isPrinter, // Indique si détecté automatiquement comme imprimante
            'suggestedConfig': {
              'ip': deviceId,
              'port': 0,
              'name': displayName,
              'connection_type': 'usb',
              'type': 'general',
              'is_enabled': true,
              'paper_width_mm': 80,
              if (vendorId != null) 'usb_vendor_id': vendorId is int ? vendorId : int.tryParse(vendorId.toString()),
              if (productId != null) 'usb_product_id': productId is int ? productId : int.tryParse(productId.toString()),
              if (manufacturer != null) 'usb_vendor_name': manufacturer.toString(),
            },
          });
          seenDeviceIds.add(deviceId);

          if (isPrinter) {
            print('✅ Imprimante USB identifiée: $displayName (confiance: $confidence)');
          } else if (confidenceScore >= 50) {
            print('⚠️ Périphérique USB probablement une imprimante: $displayName (confiance: $confidence, score: $confidenceScore)');
          } else {
            print('📱 Périphérique USB détecté (peut être une imprimante): $displayName (confiance: $confidence, score: $confidenceScore)');
          }
        }
      }

      // Ajouter les imprimantes Windows installées (nom + port)
      if (io.Platform.isWindows) {
        try {
          final winPrinters = winraw.WindowsRawPrinter.listPrinters();
          for (final printer in winPrinters) {
            final name = (printer['name'] ?? '').trim();
            final port = (printer['port'] ?? '').trim();
            if (name.isEmpty) continue;

            final upperPort = port.toUpperCase();
            final isUsbPort = RegExp(r'^(USB|COM|LPT)\d+$').hasMatch(upperPort);
            if (!isUsbPort) continue;

            final deviceId = 'USB:$port';
            if (seenDeviceIds.contains(deviceId)) continue;

            detectedPrinters.add({
              'found': true,
              'ip': deviceId,
              'port': 0,
              'name': name,
              'deviceId': deviceId,
              'deviceName': name,
              'portName': port,
              'vendorId': null,
              'productId': null,
              'manufacturer': null,
              'protocol': 'usb',
              'connectionType': 'usb',
              'type': 'network',
              'confidence': 'high',
              'confidenceScore': 90,
              'isPrinter': true,
              'autoDetected': true,
              'suggestedConfig': {
                'ip': deviceId,
                'port': 0,
                'name': name,
                'connection_type': 'usb',
                'type': 'general',
                'is_enabled': true,
                'paper_width_mm': 80,
              },
            });
            seenDeviceIds.add(deviceId);
          }
        } catch (e) {
          print('⚠️ Windows printer enumeration failed: $e');
        }
      }

      // Si aucune imprimante identifiée mais des périphériques trouvés, afficher un message
      if (detectedPrinters.isEmpty && allDevices.isNotEmpty) {
        print('⚠️ Aucune imprimante identifiée parmi ${allDevices.length} périphérique(s) USB trouvé(s)');
        print('📋 Périphériques trouvés:');
        for (final device in allDevices) {
          print('   - ${device['name']}');
        }
        print('💡 Si votre imprimante est dans la liste ci-dessus, vous pouvez:');
        print('   1. Essayer de l\'ajouter manuellement avec son nom exact');
        print('   2. Vérifier que les pilotes de l\'imprimante sont installés');
        print('   3. Redémarrer l\'application après avoir installé les pilotes');
      }

      // Trier par score de confiance (les imprimantes identifiées en premier)
      detectedPrinters.sort((a, b) {
        final scoreA = a['confidenceScore'] as int? ?? 0;
        final scoreB = b['confidenceScore'] as int? ?? 0;
        return scoreB.compareTo(scoreA); // Tri décroissant
      });

      final identifiedCount = detectedPrinters.where((p) => p['isPrinter'] == true).length;
      final totalCount = detectedPrinters.length;
      
      print('✅ Scan USB terminé:');
      print('   - $identifiedCount imprimante(s) identifiée(s) automatiquement');
      print('   - $totalCount périphérique(s) USB détecté(s) au total');
      if (totalCount > identifiedCount) {
        print('   - ${totalCount - identifiedCount} périphérique(s) peuvent être des imprimantes (sélection manuelle possible)');
      }
      
      return detectedPrinters;
    } catch (e, stackTrace) {
      print('❌ Erreur lors du scan USB: $e');
      print('Stack trace: $stackTrace');
      
      // Messages d'aide selon le type d'erreur
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        print('💡 Erreur de permission. Sur Windows, vérifiez que:');
        print('   1. L\'application a les droits d\'accès USB');
        print('   2. Les pilotes de l\'imprimante sont installés');
        print('   3. L\'imprimante est reconnue dans le Gestionnaire de périphériques Windows');
      } else if (e.toString().contains('not found') || e.toString().contains('not available')) {
        print('💡 Service USB non disponible. Vérifiez que:');
        print('   1. Vous n\'êtes pas en mode web');
        print('   2. Le plugin print_usb est correctement installé');
        print('   3. Les dépendances natives sont compilées');
      }
      
      rethrow;
    }
  }

  /// Teste la connexion à une imprimante USB spécifique
  /// L'ID peut être au format:
  /// - USB:vendorId:productId (ex: USB:04f9:2042) - Format recommandé, plus fiable
  /// - USB:deviceName (ex: USB:EPSON TM-T20) - Format fallback, moins fiable
  static Future<bool> testUsbConnection(String deviceId) async {
    if (kIsWeb) {
      return false;
    }
    if (!io.Platform.isWindows) {
      print('⚠️ USB disponible uniquement sur Windows dans cette version');
      return false;
    }

    try {
      print('🔍 Test de connexion USB: $deviceId');

      // Windows: si on a un port direct (USB001/COMx/LPTx), tester l'ouverture
      if (io.Platform.isWindows) {
        final windowsPort = _extractWindowsPort(deviceId);
        if (windowsPort != null) {
          final target = windowsPort.startsWith(r'\\.\')
              ? windowsPort
              : r'\\.\' + windowsPort;
          try {
            final file = io.File(target);
            final raf = await file.open(mode: io.FileMode.write);
            await raf.close();
            print('✅ Port Windows accessible: $target');
            return true;
          } catch (e) {
            print('❌ Port Windows inaccessible: $target - $e');
            return false;
          }
        }
      }
      
      // Obtenir tous les périphériques USB
      final devices = await PrintUsb.getList();
      
      dynamic device;
      
      // Vérifier le format de l'ID
      if (deviceId.contains(':') && deviceId.split(':').length == 3) {
        // Format: USB:vendorId:productId (ex: USB:04f9:2042)
        final parts = deviceId.split(':');
        final vidHex = parts[1];
        final pidHex = parts[2];
        
        print('  Recherche par VID:PID ($vidHex:$pidHex)...');
        
        // Convertir en entiers pour comparaison
        final vid = int.tryParse(vidHex, radix: 16);
        final pid = int.tryParse(pidHex, radix: 16);
        
        if (vid != null && pid != null) {
          // Chercher par Vendor ID et Product ID
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
            print('  ✅ Périphérique trouvé par VID:PID: ${device.name}');
          } catch (_) {
            throw Exception('Périphérique USB non trouvé avec VID:$vidHex PID:$pidHex');
          }
        } else {
          throw Exception('Format VID:PID invalide dans $deviceId');
        }
      } else {
        // Format: USB:deviceName (fallback)
        final deviceName = deviceId.replaceFirst('USB:', '');
        print('  Recherche par nom: $deviceName...');
        
        device = devices.firstWhere(
          (d) => d.name == deviceName,
          orElse: () => throw Exception('Périphérique USB non trouvé: $deviceName'),
        );
        print('  ✅ Périphérique trouvé par nom: ${device.name}');
      }

      // Essayer de se connecter
      final connected = await PrintUsb.connect(name: device.name);
      // print_usb n'expose pas de close() public; la connexion est gérée en interne

      print('✅ Connexion USB testée avec succès');
      return connected;
    } catch (e) {
      print('❌ Erreur lors du test USB: $e');
      print('💡 Vérifiez que:');
      print('   1. Le périphérique est branché et allumé');
      print('   2. Les pilotes sont installés');
      print('   3. L\'ID utilisé correspond au périphérique');
      return false;
    }
  }

  /// Extrait un port Windows depuis un ID USB s'il est au format USB:PORT
  static String? _extractWindowsPort(String deviceId) {
    final normalized = deviceId.trim();
    if (!normalized.toUpperCase().startsWith('USB:')) return null;
    final raw = normalized.substring(4).trim();
    if (raw.isEmpty) return null;

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
}
