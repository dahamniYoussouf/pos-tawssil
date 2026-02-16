import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for dart:io (only on native platforms)
import 'dart:io' if (dart.library.html) '../services/io_stub.dart' as io;
import '../config/app_theme.dart';
import '../services/local_printer_scanner.dart';
import '../services/local_print_service.dart';
import '../models/restaurant_printer.dart';

/// Écran de diagnostic réseau avec tests visuels
class NetworkDiagnosticsScreen extends StatefulWidget {
  const NetworkDiagnosticsScreen({super.key});

  @override
  State<NetworkDiagnosticsScreen> createState() => _NetworkDiagnosticsScreenState();
}

class _NetworkDiagnosticsScreenState extends State<NetworkDiagnosticsScreen> {
  // État du réseau
  ConnectivityResult? _connectivityResult;
  bool _isCheckingConnectivity = false;
  
  // Détection réseau
  String? _detectedNetworkBase;
  List<Map<String, dynamic>> _networkInterfaces = [];
  bool _isDetectingNetwork = false;
  String? _networkDetectionError;
  
  // Test IP
  final _testIpController = TextEditingController();
  String _testIpInput = '';
  bool _isTestingIP = false;
  List<Map<String, dynamic>> _ipTestResults = [];
  String? _testError;
  
  // Logs
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  
  // Tests spécifiques
  bool _isTestingPermissions = false;
  bool _isTestingWiFi = false;
  bool _isTestingAirplaneMode = false;
  bool _isTestingDHCP = false;
  bool _isTestingLoopback = false;
  Map<String, bool> _diagnosticTestResults = {};
  
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _addLog('⚠️ MODE WEB DÉTECTÉ', isError: true);
      _addLog('   En mode web, certaines fonctionnalités sont limitées:', isError: true);
      _addLog('   • Les sockets TCP/IP ne sont pas disponibles', isError: true);
      _addLog('   • Seuls les ports HTTP (80, 443) peuvent être testés', isError: true);
      _addLog('   • Les ports RAW (9100, 9101) ne peuvent pas être testés directement', isError: true);
      _addLog('   • Utilisez le backend ou lancez sur un appareil natif', isError: true);
    }
    _checkConnectivity();
    _detectNetwork();
  }
  
  @override
  void dispose() {
    _testIpController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }
  
  void _addLog(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] ${isError ? '❌' : 'ℹ️'} $message';
    setState(() {
      _logs.insert(0, logMessage);
      if (_logs.length > 100) {
        _logs.removeRange(100, _logs.length);
      }
    });
    
    // Auto-scroll to top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _checkConnectivity() async {
    setState(() {
      _isCheckingConnectivity = true;
    });
    
    _addLog('Vérification de la connectivité réseau...');
    
    try {
      final result = await Connectivity().checkConnectivity();
      setState(() {
        _connectivityResult = result;
        _isCheckingConnectivity = false;
      });
      
      final status = result == ConnectivityResult.none 
          ? 'Aucune connexion'
          : result.toString().split('.').last;
      _addLog('Connectivité: $status');
    } catch (e) {
      _addLog('Erreur lors de la vérification: $e', isError: true);
      setState(() {
        _isCheckingConnectivity = false;
      });
    }
  }
  
  Future<void> _detectNetwork() async {
    setState(() {
      _isDetectingNetwork = true;
      _networkDetectionError = null;
      _networkInterfaces = [];
      _detectedNetworkBase = null;
    });
    
    _addLog('Démarrage de la détection réseau...');
    
    if (kIsWeb) {
      _addLog('⚠️ Détection réseau non disponible en mode web', isError: true);
      setState(() {
        _networkDetectionError = 'Détection réseau non disponible en mode web';
        _isDetectingNetwork = false;
      });
      return;
    }
    
    try {
      // Capturer les interfaces réseau
      var interfaces = await io.NetworkInterface.list(
        includeLinkLocal: false,
        type: io.InternetAddressType.IPv4,
      );
      
      if (interfaces.isEmpty) {
        _addLog('Aucune interface trouvée, essai avec link-local...');
        interfaces = await io.NetworkInterface.list(
          includeLinkLocal: true,
          type: io.InternetAddressType.IPv4,
        );
      }
      
      final interfacesList = <Map<String, dynamic>>[];
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final isLinkLocal = addr.address.startsWith('169.254.');
          interfacesList.add({
            'name': interface.name,
            'index': interface.index,
            'address': addr.address,
            'isLoopback': addr.isLoopback,
            'isLinkLocal': isLinkLocal,
          });
          
          if (!addr.isLoopback && !isLinkLocal) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
              setState(() {
                _detectedNetworkBase = networkBase;
              });
              _addLog('Réseau détecté: $networkBase.x (depuis ${addr.address})');
            }
          }
        }
      }
      
      setState(() {
        _networkInterfaces = interfacesList;
        _isDetectingNetwork = false;
      });
      
      if (_detectedNetworkBase == null) {
        _addLog('Aucun réseau valide détecté', isError: true);
        setState(() {
          _networkDetectionError = 'Aucune interface réseau valide trouvée';
        });
      } else {
        _addLog('✅ Détection réseau réussie');
      }
    } catch (e) {
      _addLog('Erreur lors de la détection: $e', isError: true);
      setState(() {
        _networkDetectionError = e.toString();
        _isDetectingNetwork = false;
      });
    }
  }
  
  Future<void> _testIP() async {
    final ip = _testIpInput.trim();
    if (ip.isEmpty) {
      _addLog('Veuillez entrer une adresse IP', isError: true);
      return;
    }
    
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      _addLog('Adresse IP invalide', isError: true);
      return;
    }
    
    setState(() {
      _isTestingIP = true;
      _ipTestResults = [];
      _testError = null;
    });
    
    _addLog('Test de l\'IP $ip en cours...');
    
    try {
      final printers = await LocalPrinterScanner.testSpecificIP(ip);
      
      setState(() {
        _ipTestResults = printers;
        _isTestingIP = false;
      });
      
      if (printers.isEmpty) {
        _addLog('Aucune imprimante détectée à $ip', isError: true);
      } else {
        _addLog('✅ ${printers.length} imprimante(s) trouvée(s) à $ip');
        for (final printer in printers) {
          final protocol = printer['protocol'] ?? 'unknown';
          final port = printer['port'] ?? '?';
          _addLog('  - ${protocol.toUpperCase()} sur port $port');
        }
      }
    } catch (e) {
      _addLog('Erreur lors du test: $e', isError: true);
      setState(() {
        _testError = e.toString();
        _isTestingIP = false;
      });
    }
  }
  
  Future<void> _testPrinterConnection(String ip, int port) async {
    _addLog('Test de connexion rapide à $ip:$port...');
    
    if (kIsWeb) {
      _addLog('⚠️ Test de connexion TCP/IP non disponible en mode web', isError: true);
      _addLog('💡 Utilisez le backend ou lancez sur un appareil natif', isError: true);
      return;
    }
    
    try {
      final socket = await io.Socket.connect(ip, port, timeout: const Duration(seconds: 3));
      await socket.close();
      _addLog('✅ Connexion réussie à $ip:$port');
    } catch (e) {
      _addLog('❌ Connexion échouée à $ip:$port: $e', isError: true);
      _addLog('💡 Utilisez "Diagnostic" pour un test complet de tous les ports', isError: true);
    }
  }
  
  Future<void> _testDetailedPrinterDiagnostics(String ip) async {
    _addLog('=== Diagnostic détaillé de l\'imprimante $ip ===');
    
    try {
      final testPrinter = RestaurantPrinter(
        id: 'test',
        restaurantId: 'test',
        name: 'Test',
        type: 'general',
        ip: ip,
        port: 9100, // Port par défaut pour l'impression
        isEnabled: true,
        paperWidthMm: 80,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Test détaillé qui teste tous les ports
      _addLog('Test de tous les ports de l\'imprimante...');
      final results = await LocalPrintService.checkPrinterAccessibilityDetailed(
        testPrinter,
        timeout: const Duration(seconds: 3),
      );
      
      final port80Accessible = results['port80Accessible'] as bool;
      final port9100Accessible = results['port9100Accessible'] as bool;
      final port9101Accessible = results['port9101Accessible'] as bool;
      final configuredPortAccessible = results['configuredPortAccessible'] as bool;
      final recommendedPort = results['recommendedPort'] as int;
      
      _addLog('');
      _addLog('📊 RÉSULTATS DES TESTS:');
      _addLog('  Port 9100 (configuré pour test): ${configuredPortAccessible ? "✅ Accessible" : "❌ Non accessible"}');
      _addLog('  Port 80 (Interface web): ${port80Accessible ? "✅ Accessible" : "❌ Non accessible"}');
      _addLog('  Port 9100 (Impression RAW): ${port9100Accessible ? "✅ Accessible" : "❌ Non accessible"}');
      _addLog('  Port 9101 (RAW alternatif): ${port9101Accessible ? "✅ Accessible" : "❌ Non accessible"}');
      _addLog('');
      
      // Diagnostic spécifique du problème
      if (port80Accessible && !port9100Accessible && !port9101Accessible) {
        _addLog('⚠️ PROBLÈME IDENTIFIÉ:', isError: true);
        _addLog('   L\'interface web (port 80) fonctionne ✅', isError: true);
        _addLog('   Mais le port d\'impression (9100) ne répond pas ❌', isError: true);
        _addLog('');
        _addLog('🔧 SOLUTION:', isError: true);
        _addLog('   1. Ouvrez l\'interface web: http://$ip:80', isError: true);
        _addLog('   2. Allez dans "Configuration" → "Network Settings"', isError: true);
        _addLog('   3. Activez le port RAW (9100) pour l\'impression', isError: true);
        _addLog('   4. Vérifiez que le firewall autorise le port 9100', isError: true);
        _addLog('   5. Redémarrez l\'imprimante si nécessaire', isError: true);
      } else if (port80Accessible && port9100Accessible) {
        _addLog('✅ DIAGNOSTIC: Interface web ET impression accessibles');
        _addLog('💡 Utilisez le port 9100 pour l\'impression dans la configuration du POS');
      } else if (port9100Accessible) {
        _addLog('✅ Port d\'impression (9100) accessible');
        _addLog('💡 Configurez l\'imprimante avec le port 9100');
      } else if (port9101Accessible) {
        _addLog('✅ Port d\'impression alternatif (9101) accessible');
        _addLog('💡 Configurez l\'imprimante avec le port 9101');
      } else {
        _addLog('❌ Aucun port d\'impression accessible', isError: true);
        _addLog('   Vérifiez que l\'imprimante est allumée et sur le même réseau', isError: true);
      }
      
      _addLog('');
      _addLog('💡 Port recommandé pour l\'impression: $recommendedPort');
      _addLog('=== Diagnostic terminé ===');
      
    } catch (e) {
      _addLog('❌ Erreur lors du diagnostic: $e', isError: true);
    }
  }
  
  // Test des permissions réseau
  Future<void> _testNetworkPermissions() async {
    setState(() {
      _isTestingPermissions = true;
    });
    
    _addLog('Test des permissions réseau...');
    
    if (kIsWeb) {
      _addLog('⚠️ Test des permissions réseau non disponible en mode web', isError: true);
      setState(() {
        _isTestingPermissions = false;
        _diagnosticTestResults['permissions'] = false;
      });
      return;
    }
    
    try {
      // Tester si on peut lister les interfaces réseau
      final interfaces = await io.NetworkInterface.list(
        includeLinkLocal: true,
        type: io.InternetAddressType.IPv4,
      );
      
      final hasPermission = interfaces.isNotEmpty;
      
      setState(() {
        _isTestingPermissions = false;
        _diagnosticTestResults['permissions'] = hasPermission;
      });
      
      if (hasPermission) {
        _addLog('✅ Permissions réseau: OK (${interfaces.length} interface(s) trouvée(s))');
      } else {
        _addLog('❌ Permissions réseau: ÉCHEC (aucune interface trouvée)', isError: true);
        _addLog('   → Vérifiez les permissions dans les paramètres Android', isError: true);
      }
    } catch (e) {
      setState(() {
        _isTestingPermissions = false;
        _diagnosticTestResults['permissions'] = false;
      });
      _addLog('❌ Erreur lors du test des permissions: $e', isError: true);
    }
  }
  
  // Test de la connexion WiFi
  Future<void> _testWiFiConnection() async {
    setState(() {
      _isTestingWiFi = true;
    });
    
    _addLog('Test de la connexion WiFi...');
    
    try {
      final result = await Connectivity().checkConnectivity();
      final isWiFiConnected = result == ConnectivityResult.wifi;
      
      setState(() {
        _isTestingWiFi = false;
        _diagnosticTestResults['wifi'] = isWiFiConnected;
      });
      
      if (isWiFiConnected) {
        _addLog('✅ WiFi: Connecté');
        
        // Vérifier si une IP est assignée
        final networkBase = await LocalPrinterScanner.getLocalNetworkBase();
        if (networkBase != null) {
          _addLog('✅ IP assignée: Réseau $networkBase.x détecté');
        } else {
          _addLog('⚠️ WiFi connecté mais aucune IP assignée (problème DHCP)', isError: true);
        }
      } else {
        _addLog('❌ WiFi: Non connecté', isError: true);
        _addLog('   → Connectez-vous au WiFi dans les paramètres', isError: true);
      }
    } catch (e) {
      setState(() {
        _isTestingWiFi = false;
        _diagnosticTestResults['wifi'] = false;
      });
      _addLog('❌ Erreur lors du test WiFi: $e', isError: true);
    }
  }
  
  // Test du mode avion
  Future<void> _testAirplaneMode() async {
    setState(() {
      _isTestingAirplaneMode = true;
    });
    
    _addLog('Test du mode avion...');
    
    try {
      final result = await Connectivity().checkConnectivity();
      final isAirplaneMode = result == ConnectivityResult.none;
      
      setState(() {
        _isTestingAirplaneMode = false;
        _diagnosticTestResults['airplane'] = !isAirplaneMode;
      });
      
      if (isAirplaneMode) {
        _addLog('❌ Mode avion: ACTIVÉ', isError: true);
        _addLog('   → Désactivez le mode avion dans les paramètres', isError: true);
      } else {
        _addLog('✅ Mode avion: Désactivé');
      }
    } catch (e) {
      setState(() {
        _isTestingAirplaneMode = false;
        _diagnosticTestResults['airplane'] = false;
      });
      _addLog('❌ Erreur lors du test: $e', isError: true);
    }
  }
  
  // Test DHCP (vérifier si IP est assignée)
  Future<void> _testDHCP() async {
    setState(() {
      _isTestingDHCP = true;
    });
    
    _addLog('Test de l\'assignation DHCP...');
    
    if (kIsWeb) {
      _addLog('⚠️ Test DHCP non disponible en mode web', isError: true);
      setState(() {
        _isTestingDHCP = false;
        _diagnosticTestResults['dhcp'] = false;
      });
      return;
    }
    
    try {
      var interfaces = await io.NetworkInterface.list(
        includeLinkLocal: false,
        type: io.InternetAddressType.IPv4,
      );
      
      bool hasValidIP = false;
      String? assignedIP;
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('169.254.')) {
            hasValidIP = true;
            assignedIP = addr.address;
            break;
          }
        }
        if (hasValidIP) break;
      }
      
      setState(() {
        _isTestingDHCP = false;
        _diagnosticTestResults['dhcp'] = hasValidIP;
      });
      
      if (hasValidIP) {
        _addLog('✅ DHCP: IP assignée ($assignedIP)');
      } else {
        _addLog('❌ DHCP: Aucune IP assignée', isError: true);
        _addLog('   → Vérifiez la connexion WiFi et le serveur DHCP', isError: true);
        
        // Essayer avec link-local
        _addLog('   → Test avec adresses link-local...');
        interfaces = await io.NetworkInterface.list(
          includeLinkLocal: true,
          type: io.InternetAddressType.IPv4,
        );
        
        bool hasLinkLocal = false;
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (addr.address.startsWith('169.254.')) {
              hasLinkLocal = true;
              _addLog('   ⚠️ Adresse link-local trouvée: ${addr.address}');
              break;
            }
          }
        }
        
        if (!hasLinkLocal) {
          _addLog('   ❌ Aucune adresse réseau trouvée', isError: true);
        }
      }
    } catch (e) {
      setState(() {
        _isTestingDHCP = false;
        _diagnosticTestResults['dhcp'] = false;
      });
      _addLog('❌ Erreur lors du test DHCP: $e', isError: true);
    }
  }
  
  // Test des interfaces loopback
  Future<void> _testLoopback() async {
    setState(() {
      _isTestingLoopback = true;
    });
    
    _addLog('Test des interfaces loopback...');
    
    if (kIsWeb) {
      _addLog('⚠️ Test loopback non disponible en mode web', isError: true);
      setState(() {
        _isTestingLoopback = false;
        _diagnosticTestResults['loopback'] = false;
      });
      return;
    }
    
    try {
      final interfaces = await io.NetworkInterface.list(
        includeLinkLocal: true,
        type: io.InternetAddressType.IPv4,
      );
      
      int loopbackCount = 0;
      int normalCount = 0;
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.isLoopback) {
            loopbackCount++;
          } else if (!addr.address.startsWith('169.254.')) {
            normalCount++;
          }
        }
      }
      
      final onlyLoopback = normalCount == 0 && loopbackCount > 0;
      
      setState(() {
        _isTestingLoopback = false;
        _diagnosticTestResults['loopback'] = !onlyLoopback;
      });
      
      if (onlyLoopback) {
        _addLog('❌ Seules des adresses loopback sont disponibles', isError: true);
        _addLog('   → Connectez-vous à un réseau WiFi', isError: true);
      } else {
        _addLog('✅ Interfaces normales disponibles ($normalCount interface(s))');
        if (loopbackCount > 0) {
          _addLog('   ℹ️ $loopbackCount interface(s) loopback également détectée(s)');
        }
      }
    } catch (e) {
      setState(() {
        _isTestingLoopback = false;
        _diagnosticTestResults['loopback'] = false;
      });
      _addLog('❌ Erreur lors du test: $e', isError: true);
    }
  }
  
  // Test complet de tous les diagnostics
  Future<void> _runAllTests() async {
    _addLog('=== Démarrage des tests complets ===');
    
    // Réinitialiser les résultats
    setState(() {
      _diagnosticTestResults.clear();
    });
    
    // Lancer tous les tests séquentiellement
    await _testNetworkPermissions();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testAirplaneMode();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testWiFiConnection();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testDHCP();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testLoopback();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Actualiser la détection réseau
    await _detectNetwork();
    
    _addLog('=== Tests terminés ===');
    
    // Afficher un résumé
    final successCount = _diagnosticTestResults.values.where((v) => v == true).length;
    final totalCount = _diagnosticTestResults.length;
    _addLog('Résumé: $successCount/$totalCount tests réussis');
  }
  
  Widget _buildQuickTestButton() {
    final isRunning = _isTestingPermissions || _isTestingWiFi || _isTestingAirplaneMode || 
                      _isTestingDHCP || _isTestingLoopback;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      color: TawsilColors.primaryLight,
      child: InkWell(
        onTap: isRunning ? null : _runAllTests,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(TawsilSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                decoration: BoxDecoration(
                  color: TawsilColors.primary,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                ),
                child: isRunning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: TawsilSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunning ? 'Tests en cours...' : 'Test Rapide',
                      style: TawsilTextStyles.headingSmall.copyWith(
                        color: TawsilColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isRunning 
                          ? 'Exécution de tous les tests de diagnostic'
                          : 'Lance tous les tests automatiquement',
                      style: TawsilTextStyles.bodySmall.copyWith(
                        color: TawsilColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRunning)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: TawsilColors.primaryDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TawsilColors.background,
      appBar: AppBar(
        backgroundColor: TawsilColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Diagnostic Réseau',
          style: TawsilTextStyles.headingMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _runAllTests,
            tooltip: 'Lancer tous les tests',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkConnectivity();
              _detectNetwork();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TawsilSpacing.md),
          children: [
            // Bouton de test rapide (tous les tests)
            _buildQuickTestButton(),
            const SizedBox(height: TawsilSpacing.md),
            
            // État de connectivité
            _buildConnectivityCard(),
            const SizedBox(height: TawsilSpacing.md),
            
            // Détection réseau
            _buildNetworkDetectionCard(),
            const SizedBox(height: TawsilSpacing.md),
            
            // Interfaces réseau
            if (_networkInterfaces.isNotEmpty)
              _buildInterfacesCard(),
            if (_networkInterfaces.isNotEmpty)
              const SizedBox(height: TawsilSpacing.md),
            
            // Test IP
            _buildTestIPCard(),
            const SizedBox(height: TawsilSpacing.md),
            
            // Résultats de test IP
            if (_ipTestResults.isNotEmpty)
              _buildTestResultsCard(),
            if (_ipTestResults.isNotEmpty)
              const SizedBox(height: TawsilSpacing.md),
            
            // Logs
            _buildLogsCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _connectivityResult == ConnectivityResult.none
                      ? Icons.wifi_off
                      : Icons.wifi,
                  color: _connectivityResult == ConnectivityResult.none
                      ? TawsilColors.error
                      : TawsilColors.success,
                ),
                const SizedBox(width: TawsilSpacing.sm),
                Text(
                  'État de Connectivité',
                  style: TawsilTextStyles.headingSmall,
                ),
                const Spacer(),
                if (_isCheckingConnectivity)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _checkConnectivity,
                    tooltip: 'Actualiser',
                  ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            if (_connectivityResult != null)
              Container(
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                decoration: BoxDecoration(
                  color: _connectivityResult == ConnectivityResult.none
                      ? TawsilColors.error.withOpacity(0.1)
                      : TawsilColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectivityResult == ConnectivityResult.none
                          ? Icons.error_outline
                          : Icons.check_circle,
                      color: _connectivityResult == ConnectivityResult.none
                          ? TawsilColors.error
                          : TawsilColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: Text(
                        _connectivityResult == ConnectivityResult.none
                            ? 'Aucune connexion détectée'
                            : 'Connecté via ${_connectivityResult.toString().split('.').last}',
                        style: TawsilTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNetworkDetectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _detectedNetworkBase != null
                      ? Icons.network_check
                      : Icons.network_locked,
                  color: _detectedNetworkBase != null
                      ? TawsilColors.success
                      : TawsilColors.error,
                ),
                const SizedBox(width: TawsilSpacing.sm),
                Text(
                  'Détection Réseau',
                  style: TawsilTextStyles.headingSmall,
                ),
                const Spacer(),
                if (_isDetectingNetwork)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _detectNetwork,
                    tooltip: 'Réessayer',
                  ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            if (_detectedNetworkBase != null)
              Container(
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                decoration: BoxDecoration(
                  color: TawsilColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: TawsilColors.success, size: 20),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: Text(
                        'Réseau détecté: $_detectedNetworkBase.x',
                        style: TawsilTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_networkDetectionError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(TawsilSpacing.sm),
                    decoration: BoxDecoration(
                      color: TawsilColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: TawsilColors.error, size: 20),
                        const SizedBox(width: TawsilSpacing.sm),
                        Expanded(
                          child: Text(
                            'Impossible de détecter le réseau local',
                            style: TawsilTextStyles.bodyMedium.copyWith(
                              color: TawsilColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TawsilSpacing.sm),
                  Text(
                    'Tests de diagnostic:',
                    style: TawsilTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TawsilSpacing.xs),
                  Wrap(
                    spacing: TawsilSpacing.xs,
                    runSpacing: TawsilSpacing.xs,
                    children: [
                      _buildTestButton(
                        'Permissions',
                        Icons.security,
                        _isTestingPermissions,
                        _diagnosticTestResults['permissions'],
                        _testNetworkPermissions,
                      ),
                      _buildTestButton(
                        'Mode Avion',
                        Icons.airplanemode_active,
                        _isTestingAirplaneMode,
                        _diagnosticTestResults['airplane'],
                        _testAirplaneMode,
                      ),
                      _buildTestButton(
                        'WiFi',
                        Icons.wifi,
                        _isTestingWiFi,
                        _diagnosticTestResults['wifi'],
                        _testWiFiConnection,
                      ),
                      _buildTestButton(
                        'DHCP',
                        Icons.dns,
                        _isTestingDHCP,
                        _diagnosticTestResults['dhcp'],
                        _testDHCP,
                      ),
                      _buildTestButton(
                        'Loopback',
                        Icons.loop,
                        _isTestingLoopback,
                        _diagnosticTestResults['loopback'],
                        _testLoopback,
                      ),
                    ],
                  ),
                  const SizedBox(height: TawsilSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _runAllTests,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Lancer tous les tests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TawsilColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: TawsilSpacing.sm),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestButton(
    String label,
    IconData icon,
    bool isLoading,
    bool? result,
    VoidCallback onPressed,
  ) {
    Color? backgroundColor;
    Color? textColor;
    IconData displayIcon = icon;
    
    if (isLoading) {
      backgroundColor = TawsilColors.info.withOpacity(0.1);
      textColor = TawsilColors.info;
    } else if (result == true) {
      backgroundColor = TawsilColors.success.withOpacity(0.1);
      textColor = TawsilColors.success;
      displayIcon = Icons.check_circle;
    } else if (result == false) {
      backgroundColor = TawsilColors.error.withOpacity(0.1);
      textColor = TawsilColors.error;
      displayIcon = Icons.error;
    } else {
      backgroundColor = TawsilColors.background;
      textColor = TawsilColors.textPrimary;
    }
    
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(displayIcon, size: 16, color: textColor),
      label: Text(
        label,
        style: TawsilTextStyles.bodySmall.copyWith(
          color: textColor,
          fontSize: 11,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        side: BorderSide(
          color: textColor,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TawsilSpacing.sm,
          vertical: TawsilSpacing.xs,
        ),
        minimumSize: const Size(0, 32),
      ),
    );
  }
  
  Widget _buildInterfacesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: TawsilColors.primary),
                const SizedBox(width: TawsilSpacing.sm),
                Text(
                  'Interfaces Réseau (${_networkInterfaces.length})',
                  style: TawsilTextStyles.headingSmall,
                ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            ..._networkInterfaces.map((interface) {
              final isLoopback = interface['isLoopback'] as bool;
              final isLinkLocal = interface['isLinkLocal'] as bool;
              
              return Container(
                margin: const EdgeInsets.only(bottom: TawsilSpacing.xs),
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                decoration: BoxDecoration(
                  color: TawsilColors.background,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  border: Border.all(
                    color: isLoopback
                        ? TawsilColors.warning.withOpacity(0.3)
                        : isLinkLocal
                            ? TawsilColors.info.withOpacity(0.3)
                            : TawsilColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLoopback
                          ? Icons.loop
                          : isLinkLocal
                              ? Icons.link
                              : Icons.check_circle,
                      size: 18,
                      color: isLoopback
                          ? TawsilColors.warning
                          : isLinkLocal
                              ? TawsilColors.info
                              : TawsilColors.success,
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            interface['name'] as String,
                            style: TawsilTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            interface['address'] as String,
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoopback)
                      Chip(
                        label: const Text('Loopback', style: TextStyle(fontSize: 10)),
                        backgroundColor: TawsilColors.warning.withOpacity(0.2),
                        padding: EdgeInsets.zero,
                      )
                    else if (isLinkLocal)
                      Chip(
                        label: const Text('Link-Local', style: TextStyle(fontSize: 10)),
                        backgroundColor: TawsilColors.info.withOpacity(0.2),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestIPCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: TawsilColors.primary),
                const SizedBox(width: TawsilSpacing.sm),
                Text(
                  'Test d\'Adresse IP',
                  style: TawsilTextStyles.headingSmall,
                ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            TextField(
              controller: _testIpController,
              decoration: InputDecoration(
                labelText: 'Adresse IP',
                hintText: '192.168.1.10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                ),
                prefixIcon: const Icon(Icons.language),
                suffixIcon: _isTestingIP
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _testIP,
                        tooltip: 'Tester',
                      ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _testIpInput = value,
              onSubmitted: (_) => _testIP(),
            ),
            if (_testError != null)
              Padding(
                padding: const EdgeInsets.only(top: TawsilSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(TawsilSpacing.sm),
                  decoration: BoxDecoration(
                    color: TawsilColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: TawsilColors.error, size: 18),
                      const SizedBox(width: TawsilSpacing.sm),
                      Expanded(
                        child: Text(
                          _testError!,
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestResultsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: TawsilColors.success),
                const SizedBox(width: TawsilSpacing.sm),
                Text(
                  'Résultats du Test (${_ipTestResults.length})',
                  style: TawsilTextStyles.headingSmall,
                ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            ..._ipTestResults.map((result) {
              final protocol = result['protocol'] ?? 'unknown';
              final port = result['port'] ?? '?';
              final responseTime = result['responseTime'] ?? '?';
              final confidence = result['confidence'] ?? 'medium';
              final suggestedConfig = result['suggestedConfig'] as Map<String, dynamic>?;
              final suggestedPort = suggestedConfig?['port'] ?? port;
              
              return Container(
                margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                decoration: BoxDecoration(
                  color: TawsilColors.background,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  border: Border.all(
                    color: confidence == 'high'
                        ? TawsilColors.success
                        : confidence == 'medium'
                            ? TawsilColors.warning
                            : TawsilColors.error,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.print,
                          color: confidence == 'high'
                              ? TawsilColors.success
                              : confidence == 'medium'
                                  ? TawsilColors.warning
                                  : TawsilColors.error,
                        ),
                        const SizedBox(width: TawsilSpacing.sm),
                        Expanded(
                          child: Text(
                            result['name'] ?? 'Imprimante',
                            style: TawsilTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            protocol.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: TawsilColors.primaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: TawsilSpacing.xs),
                    Text(
                      'Port: $port • Temps: ${responseTime}ms • Confiance: $confidence',
                      style: TawsilTextStyles.bodySmall.copyWith(
                        color: TawsilColors.textSecondary,
                      ),
                    ),
                    if (suggestedPort != port)
                      Padding(
                        padding: const EdgeInsets.only(top: TawsilSpacing.xs),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: TawsilColors.info),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Port suggéré pour impression: $suggestedPort',
                                style: TawsilTextStyles.bodySmall.copyWith(
                                  color: TawsilColors.info,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: TawsilSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final ip = _testIpInput.trim();
                              _testPrinterConnection(ip, suggestedPort as int);
                            },
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text('Test Connexion'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TawsilColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: TawsilSpacing.sm,
                                vertical: TawsilSpacing.xs,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: TawsilSpacing.xs),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final ip = _testIpInput.trim();
                              _testDetailedPrinterDiagnostics(ip);
                            },
                            icon: const Icon(Icons.bug_report, size: 16),
                            label: const Text('Diagnostic'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TawsilSpacing.sm,
                                vertical: TawsilSpacing.xs,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: TawsilColors.primary),
                const SizedBox(width: TawsilSpacing.sm),
                Text(
                  'Logs de Diagnostic (${_logs.length})',
                  style: TawsilTextStyles.headingSmall,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Effacer'),
                ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: TawsilColors.surface,
                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                border: Border.all(color: TawsilColors.border),
              ),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun log pour le moment',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: TawsilColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      reverse: false,
                      padding: const EdgeInsets.all(TawsilSpacing.sm),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isError = log.contains('❌');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: TawsilSpacing.xs),
                          child: Text(
                            log,
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: isError
                                  ? TawsilColors.error
                                  : TawsilColors.textSecondary,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
