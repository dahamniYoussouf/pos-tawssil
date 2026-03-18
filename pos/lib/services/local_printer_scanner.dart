import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
// Conditional import for dart:io (only on native platforms)
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;

/// Service de scan local pour détecter les imprimantes sur le réseau local
/// Fonctionne directement depuis le POS sans passer par le backend
class LocalPrinterScanner {
  /// Détecte l'adresse IP locale du POS avec diagnostics détaillés
  static Future<String?> getLocalNetworkBase() async {
    if (kIsWeb) {
      print('⚠️ Détection réseau locale non disponible en mode web');
      return null;
    }
    
    try {
      print('🔍 Starting network interface detection...');
      
      // Essayer d'abord sans link-local (préféré)
      var interfaces = await io.NetworkInterface.list(
        includeLinkLocal: false,
        type: io.InternetAddressType.IPv4,
      );

      print('🔍 Network interfaces found (excluding link-local): ${interfaces.length}');
      
      // Si aucune interface trouvée, essayer avec link-local inclus
      if (interfaces.isEmpty) {
        print('⚠️ No interfaces found, trying with link-local addresses included...');
        interfaces = await io.NetworkInterface.list(
          includeLinkLocal: true,
          type: io.InternetAddressType.IPv4,
        );
        print('🔍 Network interfaces found (including link-local): ${interfaces.length}');
      }
      
      // Liste pour stocker toutes les adresses trouvées (pour diagnostic)
      final foundAddresses = <String>[];
      String? preferredNetworkBase;
      String? fallbackNetworkBase;
      
      for (final interface in interfaces) {
        print('  📡 Interface: ${interface.name} (index: ${interface.index})');
        for (final addr in interface.addresses) {
          final isLinkLocal = addr.address.startsWith('169.254.');
          print('    IP: ${addr.address} (loopback: ${addr.isLoopback}, link-local: $isLinkLocal)');
          
          // Ignorer les adresses loopback
          if (addr.isLoopback) continue;
          
          foundAddresses.add(addr.address);
          
          // Extraire la base du réseau (ex: "192.168.1" depuis "192.168.1.100")
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
            
            // Préférer les adresses non link-local
            if (!isLinkLocal && preferredNetworkBase == null) {
              preferredNetworkBase = networkBase;
              print('✅ Preferred network base: $networkBase (from ${addr.address})');
            } else if (isLinkLocal && fallbackNetworkBase == null) {
              fallbackNetworkBase = networkBase;
              print('⚠️ Fallback network base (link-local): $networkBase (from ${addr.address})');
            }
          }
        }
      }
      
      // Utiliser l'adresse préférée si disponible, sinon le fallback
      final networkBase = preferredNetworkBase ?? fallbackNetworkBase;
      
      if (networkBase != null) {
        print('✅ Using network base: $networkBase');
        return networkBase;
      }
      
      // Diagnostic détaillé si aucune adresse trouvée
      print('❌ No valid network interface found');
      print('   Found ${foundAddresses.length} address(es): ${foundAddresses.isEmpty ? "none" : foundAddresses.join(", ")}');
      print('   Possible causes:');
      print('   1. WiFi not connected');
      print('   2. WiFi connected but no IP assigned (DHCP issue)');
      print('   3. Only loopback addresses available');
      print('   4. Network permissions not granted');
      print('   5. Device in airplane mode');
      
      return null;
    } catch (e, stackTrace) {
      print('❌ Error detecting local network: $e');
      print('   Stack trace: $stackTrace');
      print('   Possible causes:');
      print('   1. Network permissions not granted');
      print('   2. Platform-specific network access issue');
      print('   3. Exception in NetworkInterface.list()');
      return null;
    }
  }


  /// Vérifie si une imprimante HTTP est disponible (fait une vraie requête HTTP)
  static Future<Map<String, dynamic>?> checkHttpPrinter(
    String ip,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // En mode web, utiliser http package au lieu de HttpClient
    if (kIsWeb) {
      try {
        final startTime = DateTime.now();
        final response = await http.get(
          Uri.parse('http://$ip:$port/'),
          headers: {
            'User-Agent': 'Tawsil-POS/1.0',
            'Accept': '*/*',
          },
        ).timeout(timeout);
        
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        
        // Vérifier que la réponse est valide (status < 500)
        if (response.statusCode >= 500) {
          return null;
        }
        
        String confidence = 'medium';
        if (responseTime < 200) {
          confidence = 'high';
        } else if (responseTime < 1000) {
          confidence = 'medium';
        } else {
          confidence = 'low';
        }
        
        return {
          'found': true,
          'ip': ip,
          'port': port,
          'responseTime': responseTime,
          'protocol': 'http',
          'confidence': confidence,
          'type': 'network',
        };
      } catch (e) {
        return null;
      }
    }
    
    try {
      final startTime = DateTime.now();
      final client = io.HttpClient();
      
      final request = await client
          .getUrl(Uri.parse('http://$ip:$port/'))
          .timeout(timeout);
      
      // Ajouter des headers pour identifier comme client
      request.headers.set('User-Agent', 'Tawsil-POS/1.0');
      request.headers.set('Accept', '*/*');
      
      final response = await request.close().timeout(timeout);
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // Lire au moins une partie de la réponse pour confirmer
      await response.drain();
      client.close();

      // Si on reçoit une réponse HTTP, c'est probablement une imprimante avec interface web
      String confidence = 'medium';
      if (responseTime < 200) {
        confidence = 'high';
      } else if (responseTime < 1000) {
        confidence = 'medium';
      } else {
        confidence = 'low';
      }

      return {
        'found': true,
        'ip': ip,
        'port': port,
        'responseTime': responseTime,
        'protocol': 'http',
        'confidence': confidence,
        'type': 'network',
      };
    } catch (e) {
      // Pas d'imprimante HTTP à cette adresse
      return null;
    }
  }

  /// Vérifie si une imprimante est disponible à une adresse IP et un port donnés
  static Future<Map<String, dynamic>?> checkPrinterAtIP(
    String ip,
    int port, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    // En mode web, seuls les ports HTTP/HTTPS sont testables directement
    if (kIsWeb) {
      if (port == 80 || port == 443) {
        return await checkHttpPrinter(ip, port, timeout: timeout);
      } else {
        // Pour les ports RAW (9100, 9101), on ne peut pas tester en mode web
        // Retourner null pour indiquer qu'on ne peut pas tester
        print('⚠️ Mode web: Les ports RAW ($port) ne peuvent pas être testés directement');
        print('💡 Utilisez le backend pour tester les ports RAW, ou testez depuis un appareil natif');
        return null;
      }
    }
    
    try {
      final startTime = DateTime.now();
      
      // Pour les ports HTTP/HTTPS, faire une vraie requête HTTP
      if (port == 80 || port == 443) {
        return await checkHttpPrinter(ip, port, timeout: timeout);
      }
      
      // Pour les autres ports (RAW, IPP, LPD), utiliser une connexion TCP simple
      final socket = await io.Socket.connect(
        ip,
        port,
        timeout: timeout,
      ).timeout(timeout);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await socket.close();

      // Déterminer le protocole selon le port
      String protocol = 'raw';
      if (port == 631) {
        protocol = 'ipp';
      } else if (port == 515) {
        protocol = 'lpd';
      } else if (port == 80 || port == 443) {
        protocol = 'http';
      }

      // Déterminer la confiance selon le temps de réponse
      String confidence = 'medium';
      if (responseTime < 100) {
        confidence = 'high';
      } else if (responseTime < 500) {
        confidence = 'medium';
      } else {
        confidence = 'low';
      }

      return {
        'found': true,
        'ip': ip,
        'port': port,
        'responseTime': responseTime,
        'protocol': protocol,
        'confidence': confidence,
        'type': 'network',
      };
    } catch (e) {
      // Pas d'imprimante à cette adresse
      return null;
    }
  }

  /// Teste manuellement une IP spécifique avec plusieurs ports
  /// Utile pour tester une imprimante connue qui n'a pas été détectée automatiquement
  /// Cette fonction fonctionne MÊME si getLocalNetworkBase() échoue (pas besoin de détecter le réseau)
  static Future<List<Map<String, dynamic>>> testSpecificIP(
    String ip, {
    List<int>? ports,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final detectedPrinters = <Map<String, dynamic>>[];
    
    // Ports à tester par défaut (priorité au port 9100 pour RAW)
    final portsToTest = ports ?? [9100, 9101, 631, 515, 80, 443];
    
    print('🔍 Testing specific IP: $ip on ports ${portsToTest.join(", ")}...');
    
    bool httpDetected = false;
    bool rawDetected = false;
    
    for (final port in portsToTest) {
      try {
        final result = await checkPrinterAtIP(ip, port, timeout: timeout);
        if (result != null && result['found'] == true) {
          final protocol = result['protocol'] as String;
          final ipValue = result['ip'] as String;
          
          if (protocol == 'http' && port == 80) {
            httpDetected = true;
          }
          if (protocol == 'raw' && (port == 9100 || port == 9101)) {
            rawDetected = true;
          }
          
          // Formater l'IP selon le protocole
          String formattedIp = ipValue;
          if (protocol == 'ipp') {
            formattedIp = 'IPP:http://$ipValue:$port/ipp/print';
          } else if (protocol == 'http') {
            formattedIp = 'HTTP:http://$ipValue:$port/print';
          } else if (protocol == 'lpd') {
            formattedIp = 'LPD:$ipValue:lp';
          }

          // Construire un nom intelligent
          final printerName = 'Imprimante $ipValue';

          // Pour l'impression ESC/POS, utiliser le port 9100 par défaut (port standard RAW)
          // Même si on détecte HTTP sur port 80, on suggère 9100 pour l'impression
          int suggestedPort = port;
          String suggestedProtocol = protocol;
          
          if (protocol == 'http' && port == 80) {
            // Pour les imprimantes avec interface web, tester aussi le port 9100
            print('ℹ️ HTTP printer detected on port 80, testing port 9100 (RAW) for printing...');
            
            // Tester le port 9100 pour voir s'il est disponible pour l'impression RAW
            try {
              final rawTest = await checkPrinterAtIP(ip, 9100, timeout: timeout);
              if (rawTest != null && rawTest['found'] == true) {
                suggestedPort = 9100;
                suggestedProtocol = 'raw';
                rawDetected = true;
                print('✅ Port 9100 (RAW) is available for printing');
              } else {
                // Si le port 9100 n'est pas disponible, suggérer d'autres ports communs
                print('⚠️ Port 9100 not available, will use HTTP or suggest alternative ports');
                // Tester aussi 9101
                final rawTest9101 = await checkPrinterAtIP(ip, 9101, timeout: timeout);
                if (rawTest9101 != null && rawTest9101['found'] == true) {
                  suggestedPort = 9101;
                  suggestedProtocol = 'raw';
                  rawDetected = true;
                  print('✅ Port 9101 (RAW) is available for printing');
                } else {
                  // Garder HTTP comme fallback
                  suggestedPort = 80;
                  suggestedProtocol = 'http';
                  print('⚠️ No RAW port available, will use HTTP (may require different print method)');
                }
              }
            } catch (e) {
              print('⚠️ Error testing RAW port 9100: $e');
              suggestedPort = 9100; // Suggérer quand même 9100
              suggestedProtocol = 'raw';
            }
          }

          detectedPrinters.add({
            'ip': formattedIp,
            'port': port,
            'responseTime': result['responseTime'],
            'type': 'network',
            'protocol': protocol,
            'name': '$printerName (${protocol.toUpperCase()})',
            'confidence': result['confidence'],
            'suggestedConfig': {
              'ip': ipValue,
              'port': suggestedPort, // Utiliser le port suggéré (9100 pour RAW par défaut)
              'name': printerName,
              'type': 'general',
              'is_enabled': true,
              'paper_width_mm': 80,
              'protocol': suggestedProtocol, // Ajouter le protocole suggéré
            },
          });

          print('✅ Found ${protocol.toUpperCase()} printer: $printerName at $ipValue:$port');
        }
      } catch (e) {
        // Ignorer les erreurs pour ce port
        print('⚠️ Port $port on $ip: ${e.toString()}');
      }
    }
    
    // Si on a détecté HTTP mais pas RAW, ajouter une suggestion pour tester 9100 manuellement
    if (httpDetected && !rawDetected) {
      if (kIsWeb) {
        print('💡 HTTP interface detected but RAW port cannot be tested in web mode.');
        print('💡 Solution: Use backend to test RAW ports, or run POS on native device (Android/iOS)');
      } else {
        print('💡 HTTP interface detected but RAW port not confirmed. The printer may use port 9100 for printing.');
      }
    }
    
    // En mode web, ajouter un message d'avertissement si aucun port RAW n'a été testé
    if (kIsWeb && detectedPrinters.isEmpty) {
      print('⚠️ Aucune imprimante détectée en mode web');
      print('💡 Les ports RAW (9100, 9101) ne peuvent pas être testés en mode web');
      print('💡 Solutions:');
      print('   1. Utilisez le backend pour scanner les imprimantes');
      print('   2. Lancez le POS sur un appareil natif (Android/iOS)');
      print('   3. Testez uniquement les ports HTTP (80, 443)');
    }
    
    // Trier par temps de réponse, puis par priorité (RAW > HTTP > autres)
    detectedPrinters.sort((a, b) {
      final protocolA = a['protocol'] as String;
      final protocolB = b['protocol'] as String;
      
      // Priorité: raw > http > autres
      int priorityA = protocolA == 'raw' ? 0 : (protocolA == 'http' ? 1 : 2);
      int priorityB = protocolB == 'raw' ? 0 : (protocolB == 'http' ? 1 : 2);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      final timeA = a['responseTime'] as int? ?? 9999;
      final timeB = b['responseTime'] as int? ?? 9999;
      return timeA.compareTo(timeB);
    });
    
    print('✅ Test completed: ${detectedPrinters.length} printer(s) found at $ip');
    return detectedPrinters;
  }

  /// Scanne une plage d'adresses IP pour trouver des imprimantes
  static Future<List<Map<String, dynamic>>> scanNetworkForPrinters({
    String? networkBase,
    int startHost = 1,
    int endHost = 254,
    List<int>? ports,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final detectedPrinters = <Map<String, dynamic>>[];

    // Détecter la base du réseau si non fournie
    String? base = networkBase;
    if (base == null) {
      print('🔍 Detecting local network...');
      base = await getLocalNetworkBase();
      if (base == null) {
        print('⚠️ Impossible de détecter le réseau local');
        print('💡 Vérifiez que le POS est connecté au WiFi');
        throw Exception('Impossible de détecter le réseau local. Vérifiez la connexion WiFi.');
      }
    }
    
    print('✅ Using network base: $base');

    // Ports à scanner (par défaut: ports communs d'imprimantes)
    final portsToScan = ports ?? [9100, 9101, 631, 515, 80];

    final totalScans = (endHost - startHost + 1) * portsToScan.length;
    print('🔍 Scanning network ${base}.$startHost-$endHost on ports ${portsToScan.join(", ")}...');
    print('   Total scans: $totalScans (timeout: ${timeout.inSeconds}s per connection)');

    // Scanner en parallèle avec limite de concurrence
    const maxConcurrent = 30; // Augmenté pour être plus rapide
    final scanPromises = <Future<void>>[];
    int activeScans = 0;
    int completedScans = 0;
    int foundCount = 0;

    for (int host = startHost; host <= endHost; host++) {
      final ip = '$base.$host';

      for (final port in portsToScan) {
        // Attendre si on a trop de scans en cours
        while (activeScans >= maxConcurrent) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        activeScans++;
        final scanFuture = checkPrinterAtIP(ip, port, timeout: timeout).then((result) {
          activeScans--;
          completedScans++;
          
          // Afficher la progression tous les 50 scans
          if (completedScans % 50 == 0) {
            print('   Progress: $completedScans/$totalScans (${foundCount} found)');
          }
          
          if (result != null && result['found'] == true) {
            foundCount++;
            final protocol = result['protocol'] as String;
            final ipValue = result['ip'] as String;
            
            // Formater l'IP selon le protocole
            String formattedIp = ipValue;
            if (protocol == 'ipp') {
              formattedIp = 'IPP:http://$ipValue:$port/ipp/print';
            } else if (protocol == 'http') {
              formattedIp = 'HTTP:http://$ipValue:$port/print';
            } else if (protocol == 'lpd') {
              formattedIp = 'LPD:$ipValue:lp';
            }

          // Construire un nom intelligent
          final printerName = 'Imprimante $ipValue';

          // Pour l'impression ESC/POS, utiliser le port 9100 par défaut (port standard RAW)
          // Même si on détecte HTTP sur port 80, on suggère 9100 pour l'impression
          int suggestedPort = port;
          if (protocol == 'http' && port == 80) {
            // Pour les imprimantes avec interface web, tester automatiquement le port 9100
            print('ℹ️ HTTP printer detected on port 80, testing port 9100 (RAW) for printing...');
            
            // Tester le port 9100 en arrière-plan (ne pas bloquer le scan)
            // On suggère 9100 par défaut, l'utilisateur pourra tester
            suggestedPort = 9100;
            print('💡 Suggesting port 9100 (RAW) for printing. If it doesn\'t work, try port 9101 or check printer settings.');
          }

          detectedPrinters.add({
            'ip': formattedIp,
            'port': port,
            'responseTime': result['responseTime'],
            'type': 'network',
            'protocol': protocol,
            'name': '$printerName (${protocol.toUpperCase()})',
            'confidence': result['confidence'],
            'suggestedConfig': {
              'ip': ipValue,
              'port': suggestedPort, // Utiliser le port suggéré (9100 pour RAW par défaut)
              'name': printerName,
              'type': 'general',
              'is_enabled': true,
              'paper_width_mm': 80,
            },
          });

            print('✅ Found ${protocol.toUpperCase()} printer: $printerName at $ipValue:$port (${result['responseTime']}ms)');
          }
        }).catchError((e) {
          activeScans--;
          completedScans++;
          // Ignorer les erreurs silencieusement (timeouts normaux)
        });

        scanPromises.add(scanFuture);
      }
    }

    // Attendre la fin de tous les scans
    print('⏳ Waiting for all scans to complete...');
    await Future.wait(scanPromises);

    // Trier par temps de réponse
    detectedPrinters.sort((a, b) {
      final timeA = a['responseTime'] as int? ?? 9999;
      final timeB = b['responseTime'] as int? ?? 9999;
      return timeA.compareTo(timeB);
    });

    print('✅ Scan completed: ${detectedPrinters.length} printer(s) found out of $totalScans scans');
    if (detectedPrinters.isEmpty) {
      print('💡 Aucune imprimante détectée. Suggestions:');
      print('   1. Vérifiez que l\'imprimante est allumée');
      print('   2. Vérifiez que l\'imprimante est sur le même réseau WiFi que le POS');
      print('   3. Utilisez "Tester IP" pour tester manuellement l\'IP de l\'imprimante');
      print('   4. Vérifiez que le firewall n\'bloque pas les ports ${portsToScan.join(", ")}');
    }
    return detectedPrinters;
  }

  /// Scanne rapidement les imprimantes sur le réseau local
  /// Version simplifiée qui scanne seulement le port 9100 (le plus commun)
  static Future<List<Map<String, dynamic>>> quickScan({
    String? networkBase,
    int startHost = 1,
    int endHost = 254,
  }) async {
    return await scanNetworkForPrinters(
      networkBase: networkBase,
      startHost: startHost,
      endHost: endHost,
      ports: [9100], // Port RAW le plus commun
      timeout: const Duration(seconds: 1),
    );
  }

  /// Scanne complet avec tous les ports
  static Future<List<Map<String, dynamic>>> fullScan({
    String? networkBase,
    int startHost = 1,
    int endHost = 254,
  }) async {
    return await scanNetworkForPrinters(
      networkBase: networkBase,
      startHost: startHost,
      endHost: endHost,
      ports: [9100, 9101, 631, 515, 80], // RAW, RAW alternatif, IPP, LPD, HTTP
      timeout: const Duration(seconds: 3), // Timeout augmenté pour les imprimantes lentes
    );
  }
}
