import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../config/app_theme.dart';
import '../models/restaurant_printer.dart';
import '../services/api_service.dart';
import '../services/print_service.dart';
import '../services/local_print_service.dart';
import '../services/local_printer_scanner.dart';
import '../services/bluetooth_printer_scanner.dart';
import '../services/usb_printer_scanner.dart';
import 'network_diagnostics_screen.dart';
import 'dart:async';
import 'dart:math';

enum _PrinterMenuAction {
  addPrinter,
  diagnostics,
  scanNetwork,
  scanUsb,
  scanBluetooth,
  testIp,
  deleteAll,
}

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final ApiService _apiService = ApiService();
  final PrintService _printService = PrintService();
  
  List<RestaurantPrinter> _printers = [];
  bool _loading = false;
  String? _error;
  String? _success;

  // Configuration locale des imprimantes sélectionnées
  String? _selectedCaissePrinterId;
  String? _selectedCuisinePrinterId;
  String? _selectedGeneralPrinterId;

  // Modal de création/modification d'imprimante
  bool _isCreatingPrinter = false;
  bool _isPrinterDialogOpen = false;
  RestaurantPrinter? _editingPrinter;
  final _printerFormKey = GlobalKey<FormState>();
  String _printerFormName = '';
  String _printerFormType = 'general';
  String _printerFormConnectionType = 'network';
  String _printerFormIp = '';
  String _printerFormPort = '9100';
  bool _printerFormEnabled = true;
  String _printerFormPaperWidth = '80';
  String? _printerFormError;

  // Scan automatique
  bool _isScanning = false;
  bool _isScanningBluetooth = false;
  bool _isScanningUsb = false;
  List<Map<String, dynamic>> _detectedPrinters = [];
  bool _showDetectedPrinters = false;

  // Test IP manuel
  bool _isTestingIP = false;
  String _testIpInput = '';
  final _testIpController = TextEditingController();

  // Test de connexion des imprimantes
  final Map<String, bool> _testingConnections = {};
  final Map<String, bool?> _connectionStatus = {}; // null = non testé, true = OK, false = erreur

  /// Incrémenté quand on génère un ID USB aléatoire (force le rebuild du champ)
  int _usbIdFormVersion = 0;
  int _printerFormVersion = 0;
  String _usbIdMode = 'vidpid'; // 'vidpid' | 'name'
  Map<String, dynamic>? _selectedUsbDetectedPrinter;

  String _deriveConnectionTypeFromPrinter(RestaurantPrinter printer) {
    final ip = printer.ip.trim();
    final rawType = (printer.connectionType ?? 'network').toLowerCase();
    if (ip.toUpperCase().startsWith('USB:')) {
      return 'usb';
    }
    if (rawType == 'bluetooth' || printer.bluetoothDeviceId != null) {
      return 'bluetooth';
    }
    if (rawType == 'usb' || rawType == 'network') {
      return rawType;
    }
    return 'network';
  }

  String _deriveConnectionTypeFromForm(String ip, String currentType) {
    final normalized = ip.trim();
    if (normalized.toUpperCase().startsWith('USB:')) {
      return 'usb';
    }
    final current = currentType.toLowerCase();
    if (current == 'bluetooth' || current == 'usb' || current == 'network') {
      return current;
    }
    return 'network';
  }

  @override
  void initState() {
    super.initState();
    _loadPrinters();
    _loadLocalSettings();
  }

  @override
  void dispose() {
    _testIpController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _safeModalSetState(StateSetter? setModalState, VoidCallback fn) {
    if (!mounted) return;
    if (setModalState != null) {
      if (!_isPrinterDialogOpen) return;
      setModalState(fn);
      return;
    }
    setState(fn);
  }

  void _openCreatePrinterDialog() {
    _safeSetState(() {
      _editingPrinter = null;
      _printerFormName = '';
      _printerFormType = 'general';
      _printerFormConnectionType = 'network';
      _printerFormIp = '';
      _printerFormPort = '9100';
      _printerFormEnabled = true;
      _printerFormPaperWidth = '80';
      _printerFormError = null;
      _printerFormVersion++;
    });
    _showPrinterModalDialog();
  }

  void _openEditPrinterDialog(RestaurantPrinter printer) {
    _safeSetState(() {
      _editingPrinter = printer;
      _printerFormName = printer.name;
      _printerFormType = printer.type;
      _printerFormIp = printer.ip;
      _printerFormPort = printer.port.toString();
      _printerFormEnabled = printer.isEnabled;
      _printerFormPaperWidth = printer.paperWidthMm.toString();
      _printerFormError = null;
      _selectedUsbDetectedPrinter = null;

      final derivedType = _deriveConnectionTypeFromPrinter(printer);
      _printerFormConnectionType = derivedType;

      if (derivedType == 'usb') {
        _printerFormPort = '0';
        final usbIdMatch = RegExp(
          r'^USB:[0-9a-fA-F]+:[0-9a-fA-F]+$',
          caseSensitive: false,
        ).hasMatch(_printerFormIp);
        _usbIdMode = usbIdMatch ? 'vidpid' : 'name';
      } else if (derivedType == 'bluetooth') {
        _printerFormPort = '0';
        _usbIdMode = 'vidpid';
      } else if (_printerFormPort.trim().isEmpty || _printerFormPort == '0') {
        _printerFormPort = '9100';
        _usbIdMode = 'vidpid';
      } else {
        _usbIdMode = 'vidpid';
      }

      _printerFormVersion++;
    });
    _showPrinterModalDialog();
  }

  void _handleMenuAction(_PrinterMenuAction action) {
    switch (action) {
      case _PrinterMenuAction.addPrinter:
        _openCreatePrinterDialog();
        break;
      case _PrinterMenuAction.diagnostics:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NetworkDiagnosticsScreen(),
          ),
        );
        break;
      case _PrinterMenuAction.scanNetwork:
        _scanForPrinters();
        break;
      case _PrinterMenuAction.scanUsb:
        _scanUsbPrinters();
        break;
      case _PrinterMenuAction.scanBluetooth:
        _scanBluetoothPrinters();
        break;
      case _PrinterMenuAction.testIp:
        _showTestIPDialog();
        break;
      case _PrinterMenuAction.deleteAll:
        if (_printers.isEmpty || _loading) return;
        _confirmDeleteAllPrinters(context);
        break;
    }
  }

  List<Widget> _buildAppBarActions(bool isNarrow) {
    final actions = <Widget>[];
    final isBusy = _isScanning || _isTestingIP || _isScanningBluetooth || _isScanningUsb;

    if (isBusy) {
      actions.add(
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    actions.add(
      PopupMenuButton<_PrinterMenuAction>(
        tooltip: 'Plus d\'actions',
        onSelected: _handleMenuAction,
        itemBuilder: (context) {
          final items = <PopupMenuEntry<_PrinterMenuAction>>[];
          items.add(
            const PopupMenuItem(
              value: _PrinterMenuAction.addPrinter,
              child: Text('Ajouter une imprimante'),
            ),
          );
          items.add(const PopupMenuDivider());
          items.add(
            const PopupMenuItem(
              value: _PrinterMenuAction.scanNetwork,
              child: Text('Scanner le réseau'),
            ),
          );
          items.add(
            const PopupMenuItem(
              value: _PrinterMenuAction.testIp,
              child: Text('Tester une IP spécifique'),
            ),
          );
          if (!kIsWeb) {
            items.addAll([
              const PopupMenuItem(
                value: _PrinterMenuAction.scanUsb,
                child: Text('Scanner USB'),
              ),
              const PopupMenuItem(
                value: _PrinterMenuAction.scanBluetooth,
                child: Text('Scanner Bluetooth'),
              ),
            ]);
          }
          items.add(
            const PopupMenuItem(
              value: _PrinterMenuAction.diagnostics,
              child: Text('Diagnostic réseau'),
            ),
          );
          items.add(const PopupMenuDivider());
          items.add(
            const PopupMenuItem(
              value: _PrinterMenuAction.deleteAll,
              child: Text('Supprimer toutes les imprimantes'),
            ),
          );
          return items.map((item) {
            if (item is PopupMenuItem<_PrinterMenuAction> &&
                item.value == _PrinterMenuAction.deleteAll) {
              return PopupMenuItem<_PrinterMenuAction>(
                value: item.value,
                enabled: _printers.isNotEmpty && !_loading,
                child: item.child,
              );
            }
            if (isBusy &&
                (item is PopupMenuItem<_PrinterMenuAction>) &&
                item.value != _PrinterMenuAction.deleteAll &&
                item.value != _PrinterMenuAction.addPrinter) {
              return PopupMenuItem<_PrinterMenuAction>(
                value: item.value,
                enabled: false,
                child: item.child,
              );
            }
            return item;
          }).toList();
        },
        icon: const Icon(Icons.more_vert),
      ),
    );

    return actions;
  }

  List<Widget> _buildPrinterActionWidgets(RestaurantPrinter printer) {
    final actions = <Widget>[];
    actions.addAll([
      _buildConnectionTestButton(printer),
      IconButton(
        icon: const Icon(Icons.print, size: 18),
        onPressed: () => _testPrinter(printer),
        tooltip: 'Tester l\'imprimante',
        color: TawsilColors.primary,
      ),
      IconButton(
        icon: const Icon(Icons.edit, size: 18),
        onPressed: () => _openEditPrinterDialog(printer),
        tooltip: 'Modifier l\'imprimante',
        color: TawsilColors.primary,
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => _confirmDeletePrinter(context, printer),
        tooltip: 'Supprimer l\'imprimante',
        color: Colors.red,
        iconSize: 20,
      ),
    ]);

    return actions;
  }

  Widget _buildPrinterActions(RestaurantPrinter printer) {
    final actions = _buildPrinterActionWidgets(printer);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: TawsilSpacing.xs,
      runSpacing: TawsilSpacing.xs,
      children: actions,
    );
  }

  Widget _buildPrinterCard(RestaurantPrinter printer) {
    final connectionType = _deriveConnectionTypeFromPrinter(printer);
    final typeLabel = _getTypeLabel(printer.type);
    final typeColor = _getTypeColor(printer.type);
    final connectionLabel = connectionType == 'usb'
        ? 'USB'
        : connectionType == 'bluetooth'
            ? 'Bluetooth'
            : 'Réseau';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print, color: typeColor),
                const SizedBox(width: TawsilSpacing.sm),
                Expanded(
                  child: Text(
                    printer.name,
                    style: TawsilTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!printer.isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(left: TawsilSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Désactivée',
                      style: TawsilTextStyles.bodySmall.copyWith(
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.xs),
            Wrap(
              spacing: TawsilSpacing.sm,
              runSpacing: TawsilSpacing.xs,
              children: [
                _buildInfoChip('${printer.ip}:${printer.port}'),
                _buildInfoChip('${printer.paperWidthMm}mm'),
                _buildInfoChip(typeLabel),
                _buildInfoChip(connectionLabel),
              ],
            ),
            const SizedBox(height: TawsilSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: _buildPrinterActions(printer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TawsilColors.background,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(color: TawsilColors.border),
      ),
      child: Text(
        label,
        style: TawsilTextStyles.bodySmall.copyWith(
          color: TawsilColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _loadPrinters() async {
    _safeSetState(() {
      _loading = true;
      _error = null;
    });

    try {
      final printers = await _apiService.fetchRestaurantPrinters();
      _safeSetState(() {
        _printers = printers;
      });
    } catch (e) {
      _safeSetState(() {
        _error = 'Erreur lors du chargement: ${e.toString()}';
      });
    } finally {
      _safeSetState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _safeSetState(() {
      _selectedCaissePrinterId = prefs.getString('selected_caisse_printer_id');
      _selectedCuisinePrinterId = prefs.getString('selected_cuisine_printer_id');
      _selectedGeneralPrinterId = prefs.getString('selected_general_printer_id');
    });
  }

  Future<void> _savePrinterSelection(String type, String? printerId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'selected_${type}_printer_id';
    
    if (printerId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, printerId);
    }

    _safeSetState(() {
      switch (type) {
        case 'caisse':
          _selectedCaissePrinterId = printerId;
          break;
        case 'cuisine':
          _selectedCuisinePrinterId = printerId;
          break;
        case 'general':
          _selectedGeneralPrinterId = printerId;
          break;
      }
    });

    // Invalider le cache des imprimantes pour forcer le rechargement
    await _printService.invalidatePrintersCache();
    
    _safeSetState(() {
      _success = 'Configuration enregistrée';
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _safeSetState(() {
          _success = null;
        });
      }
    });
  }

  Future<void> _scanForPrinters() async {
    final startTime = DateTime.now();
    
    _safeSetState(() {
      _isScanning = true;
      _error = null;
      _success = 'Scan en cours... Cela peut prendre 1-2 minutes';
      _detectedPrinters = [];
      _showDetectedPrinters = false;
    });

    try {
      // En mode web, afficher un avertissement
      if (kIsWeb) {
        _safeSetState(() {
          _error = '?? MODE WEB DÉTECTÉ\n\n'
                   'En mode web (Chrome), les sockets TCP/IP ne sont pas disponibles.\n'
                   'Le scan réseau direct n\'est pas possible.\n\n'
                   'SOLUTIONS:\n'
                   '1. Utilisez "Tester IP" pour tester une IP spécifique (teste uniquement HTTP)\n'
                   '2. Utilisez le backend pour scanner les imprimantes\n'
                   '3. Lancez le POS sur un appareil natif:\n'
                   '   • Android: flutter run -d android\n'
                   '   • iOS: flutter run -d ios\n'
                   '   • Windows: flutter run -d windows\n\n'
                   '?? Pour tester l\'imprimante 192.168.1.10:\n'
                   '   ? Utilisez le bouton "Tester IP" (icône globe)\n'
                   '   ? Entrez 192.168.1.10\n'
                   '   ? Le système testera le port 80 (interface web)';
          _success = null;
          _isScanning = false;
        });
        return;
      }
      
      // Scanner localement depuis le POS (mode natif uniquement)
      print('?? Starting local printer scan...');
      print('?? Le scan se fait directement depuis le POS sur le réseau local');
      print('?? Le backend distant n\'est pas utilisé pour le scan');
      
      // Vérifier d'abord que le réseau est détecté
      final networkBase = await LocalPrinterScanner.getLocalNetworkBase();
      if (networkBase == null) {
        final duration = DateTime.now().difference(startTime);
        _safeSetState(() {
          _error = 'Impossible de détecter le réseau local.\n\n'
                   'Causes possibles:\n'
                   '• Le POS n\'est pas connecté au WiFi\n'
                   '• Le WiFi est connecté mais aucune IP n\'est assignée (problème DHCP)\n'
                   '• Les permissions réseau ne sont pas accordées\n'
                   '• Le mode avion est activé\n'
                   '• Seules des adresses loopback sont disponibles\n\n'
                   '?? Solution: Utilisez "Tester IP" pour tester directement l\'adresse IP de l\'imprimante.\n'
                   '   Cette fonction fonctionne même sans détection automatique du réseau.';
          _success = null;
          _isScanning = false;
        });
        print('? Network detection failed after ${duration.inSeconds}s');
        return;
      }
      
      print('? Network detected: $networkBase.x');
      
      // Lancer le scan
      final printers = await LocalPrinterScanner.fullScan(
        networkBase: networkBase,
        startHost: 1,
        endHost: 254,
      );
      final duration = DateTime.now().difference(startTime);
      
      _safeSetState(() {
        _detectedPrinters = printers;
        _showDetectedPrinters = true;
        if (printers.isEmpty) {
          _error = 'Aucune imprimante détectée après ${duration.inSeconds}s de scan.\n\n'
                   'Vérifiez que:\n'
                   '• L\'imprimante est allumée\n'
                   '• L\'imprimante est sur le même réseau WiFi que le POS ($networkBase.x)\n'
                   '• Utilisez "Tester IP" pour tester manuellement l\'IP 192.168.1.10\n'
                   '• Vérifiez que le firewall n\'bloque pas les connexions';
          _success = null;
        } else {
          _success = '${printers.length} imprimante(s) détectée(s) en ${duration.inSeconds}s';
        }
      });

      print('? Local scan completed: ${printers.length} printer(s) found in ${duration.inSeconds}s');

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _safeSetState(() {
            _success = null;
          });
        }
      });
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('? Error during local scan: $e');
      print('Stack trace: $stackTrace');
      _safeSetState(() {
        _error = 'Erreur lors du scan après ${duration.inSeconds}s:\n${e.toString()}\n\n'
                 'Le scan se fait directement depuis le POS.\n'
                 'Vérifiez la connexion WiFi du POS.';
        _success = null;
      });
    } finally {
      _safeSetState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _testSpecificIP() async {
    final ip = _testIpInput.trim();
    if (ip.isEmpty) {
      _safeSetState(() {
        _error = 'Veuillez entrer une adresse IP';
      });
      return;
    }

    // Validation basique de l'IP
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      _safeSetState(() {
        _error = 'Adresse IP invalide';
      });
      return;
    }

    _safeSetState(() {
      _isTestingIP = true;
      _error = null;
      _success = 'Test de l\'IP $ip en cours...\nCette fonction fonctionne même si le réseau n\'est pas détecté automatiquement.';
      _detectedPrinters = [];
      _showDetectedPrinters = false;
    });

    try {
      print('?? Testing specific IP: $ip (no network detection required)...');
      
      // En mode web, afficher un avertissement
      if (kIsWeb) {
        print('?? MODE WEB: Limitations détectées');
        _safeSetState(() {
          _success = 'Test en mode web...\n'
                     '?? En mode web, seuls les ports HTTP (80, 443) peuvent être testés directement.\n'
                     'Pour tester les ports RAW (9100, 9101), utilisez le backend.';
        });
      }
      
      // testSpecificIP() fonctionne indépendamment de getLocalNetworkBase()
      // Elle teste directement l'IP fournie sans avoir besoin de détecter le réseau
      final printers = await LocalPrinterScanner.testSpecificIP(ip);
      
      _safeSetState(() {
        _detectedPrinters = printers;
        _showDetectedPrinters = true;
        if (printers.isEmpty) {
          String errorMsg = 'Aucune imprimante détectée à l\'adresse $ip\n\n'
                   'Vérifiez que:\n'
                   '• L\'imprimante est allumée\n'
                   '• L\'adresse IP $ip est correcte\n'
                   '• Le POS et l\'imprimante sont sur le même réseau\n'
                   '• Aucun firewall ne bloque les connexions';
          
          if (kIsWeb) {
            errorMsg += '\n\n?? MODE WEB DÉTECTÉ:\n'
                       '• En mode web, seuls les ports HTTP (80, 443) sont testables\n'
                       '• Les ports RAW (9100, 9101) ne peuvent pas être testés directement\n'
                       '• Solutions:\n'
                       '  1. Utilisez le backend pour scanner les imprimantes\n'
                       '  2. Lancez le POS sur un appareil natif (Android/iOS)\n'
                       '  3. Testez l\'imprimante depuis l\'interface web (http://$ip:80)';
          }
          
          _error = errorMsg;
          _success = null;
        } else {
          String successMsg = '${printers.length} imprimante(s) détectée(s) à $ip';
          if (kIsWeb) {
            successMsg += '\n\n?? Mode web: Seuls les ports HTTP ont été testés';
            successMsg += '\nPour tester les ports RAW (9100), utilisez le backend ou un appareil natif';
          }
          _success = successMsg;
        }
      });

      print('? IP test completed: ${printers.length} printer(s) found at $ip');

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _safeSetState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      print('? Error testing IP: $e');
      _safeSetState(() {
        _error = 'Erreur lors du test: ${e.toString()}\n\n'
                 'Cette fonction teste directement l\'IP sans avoir besoin de détecter le réseau.\n'
                 'Si l\'erreur persiste, vérifiez que l\'imprimante est accessible depuis le POS.';
        _success = null;
      });
    } finally {
      _safeSetState(() {
        _isTestingIP = false;
      });
    }
  }

  void _showTestIPDialog() {
    _testIpController.text = '';
    _testIpInput = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tester une adresse IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez l\'adresse IP de l\'imprimante à tester (ex: 192.168.1.10)',
              style: TawsilTextStyles.bodySmall.copyWith(
                color: TawsilColors.textSecondary,
              ),
            ),
            const SizedBox(height: TawsilSpacing.md),
            TextField(
              controller: _testIpController,
              decoration: InputDecoration(
                labelText: 'Adresse IP',
                hintText: '192.168.1.10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                ),
                prefixIcon: const Icon(Icons.language),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _testIpInput = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isTestingIP
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _isTestingIP
                ? null
                : () {
                    Navigator.of(context).pop();
                    _testSpecificIP();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: TawsilColors.primary,
            ),
            child: _isTestingIP
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tester'),
          ),
        ],
      ),
    );
  }

  Future<void> _useDetectedPrinter(Map<String, dynamic> detectedPrinter) async {
    // Extraire les informations de l'imprimante détectée
    final suggestedConfig = detectedPrinter['suggestedConfig'] as Map<String, dynamic>?;
    
    // Si suggestedConfig n'existe pas, extraire depuis les champs directs
    String ip = '';
    int port = 9100;
    String name = '';
    
    if (suggestedConfig != null) {
      ip = suggestedConfig['ip'] ?? '';
      port = suggestedConfig['port'] ?? 9100;
      name = suggestedConfig['name'] ?? '';
    } else {
      // Extraire depuis les champs directs
      final ipField = detectedPrinter['ip'] as String? ?? '';
      // Parser l'IP depuis le format (peut être "192.168.1.10" ou "HTTP:http://192.168.1.10:80/print")
      if (ipField.contains('://')) {
        final uri = Uri.tryParse(ipField.replaceFirst(RegExp(r'^[A-Z]+:'), ''));
        if (uri != null) {
          ip = uri.host;
          port = uri.hasPort ? uri.port : 9100;
        }
      } else {
        ip = ipField;
      }
      port = detectedPrinter['port'] as int? ?? 9100;
      name = detectedPrinter['name'] as String? ?? 'Imprimante $ip';
    }

    _safeSetState(() {
      _editingPrinter = null;
      _printerFormName = name.isEmpty ? 'Imprimante $ip' : name;
      _printerFormType = suggestedConfig?['type'] ?? 'general';
      
      // Détecter le type de connexion
      _printerFormConnectionType = detectedPrinter['connectionType'] as String? ?? 
                                   suggestedConfig?['connection_type'] as String? ?? 
                                   'network';
      _printerFormIp = ip;
      _printerFormPort = port.toString();
      
      _printerFormEnabled = suggestedConfig?['is_enabled'] ?? true;
      _printerFormPaperWidth = (suggestedConfig?['paper_width_mm'] ?? 80).toString();
      _printerFormError = null;
      _printerFormVersion++;
    });

    _showPrinterModalDialog();
  }

  Future<void> _testPrinter(RestaurantPrinter printer) async {
    _safeSetState(() {
      _error = null;
      _success = 'Envoi du ticket de test...';
    });

    try {
      // Récupérer le nom du restaurant
      final prefs = await SharedPreferences.getInstance();
      final restaurantName = prefs.getString('restaurant_name') ?? 'Restaurant';
      
      // Utiliser l'impression locale directement (pas de backend)
      await LocalPrintService.printTestTicketDirectly(
        printer,
        restaurantName: restaurantName,
      );
      
      _safeSetState(() {
        _success = 'Ticket de test envoyé avec succès à ${printer.name}';
      });
    } catch (e) {
      _safeSetState(() {
        _error = 'Erreur lors du test: ${e.toString()}';
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _safeSetState(() {
          _success = null;
        });
      }
    });
  }

  Future<void> _scanUsbPrinters({StateSetter? setModalState}) async {
    final updateState = (VoidCallback fn) => _safeModalSetState(setModalState, fn);
    if (kIsWeb) {
      updateState(() {
        _error = 'USB non disponible en mode web';
      });
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.windows) {
      updateState(() {
        _error = 'USB uniquement sur Windows dans cette version.\n'
                 'Sur Android/iOS, utilisez Bluetooth ou une imprimante réseau.';
      });
      return;
    }

    updateState(() {
      _isScanningUsb = true;
      _error = null;
      _success = 'Scan USB en cours...';
      _detectedPrinters = [];
      _showDetectedPrinters = false;
    });

    try {
      print('?? Starting USB printer scan...');
      
      // Vérifier d'abord si USB est disponible
      final isAvailable = await UsbPrinterScanner.isUsbAvailable();
      if (!isAvailable) {
        updateState(() {
          _error = 'USB non disponible.\n\n'
                   'Vérifiez que:\n'
                   '• Vous n\'êtes pas en mode web\n'
                   '• Le plugin print_usb est installé\n'
                   '• Les dépendances natives sont compilées';
          _success = null;
          _isScanningUsb = false;
        });
        return;
      }
      
      // Lister tous les périphériques USB pour diagnostic
      final allDevices = await UsbPrinterScanner.listAllUsbDevices();
      print('?? Tous les périphériques USB: ${allDevices.join(", ")}');
      
      // Scanner TOUS les périphériques USB (détection automatique améliorée)
      // Le système détecte automatiquement tous les périphériques et les classe par probabilité
      final printers = await UsbPrinterScanner.scanForPrinters(
        scanDuration: const Duration(seconds: 5),
        showAllDevices: true, // Toujours activé pour détecter tous les périphériques
      );

      updateState(() {
        _detectedPrinters = printers;
        _showDetectedPrinters = true;
        if (printers.isEmpty) {
          String errorMsg = 'Aucune imprimante USB détectée.\n\n'
                   'Vérifiez que:\n'
                   '• L\'imprimante est branchée en USB\n'
                   '• Les pilotes USB de l\'imprimante sont installés\n'
                   '• L\'imprimante est allumée\n'
                   '• L\'imprimante apparaît dans le Gestionnaire de périphériques Windows\n'
                   '• Les permissions USB sont accordées\n\n';
          
          if (allDevices.isNotEmpty) {
            errorMsg += '?? Périphériques USB trouvés (${allDevices.length}):\n';
            for (final device in allDevices) {
              errorMsg += '   • $device\n';
            }
            errorMsg += '\n?? Si votre imprimante est dans la liste ci-dessus:\n'
                       '1. Ajoutez-la manuellement avec son nom exact\n'
                       '2. Le nom doit correspondre exactement à celui affiché ci-dessus';
          } else {
            errorMsg += '?? Aucun périphérique USB détecté par Windows.\n'
                       'Vérifiez le Gestionnaire de périphériques Windows.';
          }
          
          _error = errorMsg;
          _success = null;
        } else {
          final identifiedCount = printers.where((p) => p['isPrinter'] == true).length;
          final highConfidenceCount = printers.where((p) => (p['confidenceScore'] as int? ?? 0) >= 80).length;
          final allCount = printers.length;
          
          if (identifiedCount == allCount) {
            _success = '${printers.length} imprimante(s) USB détectée(s) automatiquement';
            _error = null;
          } else {
            _success = '$identifiedCount imprimante(s) identifiée(s), $highConfidenceCount probable(s), $allCount périphérique(s) USB détecté(s)';
            
            // Afficher les périphériques avec faible confiance pour sélection manuelle
            final lowConfidence = printers.where((p) => (p['confidenceScore'] as int? ?? 0) < 50).toList();
            if (lowConfidence.isNotEmpty) {
              String lowConfidenceNames = lowConfidence.map((p) {
                final name = p['name'] as String;
                final score = p['confidenceScore'] as int? ?? 0;
                return '$name (score: $score)';
              }).join(', ');
              _error = 'Périphériques USB détectés (peuvent être des imprimantes):\n'
                       '$lowConfidenceNames';
            } else {
              _error = null;
            }
          }
        }
        _isScanningUsb = false;
      });

      print('? USB scan completed: ${printers.length} printer(s) found');
    } catch (e, stackTrace) {
      print('? Error during USB scan: $e');
      print('Stack trace: $stackTrace');
      updateState(() {
        String errorMsg = 'Erreur lors du scan USB:\n${e.toString()}\n\n';
        
        if (e.toString().contains('permission') || e.toString().contains('Permission')) {
          errorMsg += 'Erreur de permission. Sur Windows:\n'
                     '• Vérifiez que l\'application a les droits d\'accès USB\n'
                     '• Les pilotes de l\'imprimante doivent être installés\n'
                     '• L\'imprimante doit être reconnue dans le Gestionnaire de périphériques';
        } else if (e.toString().contains('not found') || e.toString().contains('not available')) {
          errorMsg += 'Service USB non disponible:\n'
                     '• Vérifiez que vous n\'êtes pas en mode web\n'
                     '• Le plugin print_usb doit être installé\n'
                     '• Les dépendances natives doivent être compilées';
        } else {
          errorMsg += 'Vérifiez que:\n'
                     '• Les pilotes USB sont installés\n'
                     '• Les permissions sont accordées\n'
                     '• L\'imprimante est reconnue par Windows';
        }
        
        _error = errorMsg;
        _success = null;
        _isScanningUsb = false;
      });
    }
  }

  Future<void> _scanBluetoothPrinters({StateSetter? setModalState}) async {
    final updateState = (VoidCallback fn) => _safeModalSetState(setModalState, fn);
    if (kIsWeb) {
      updateState(() {
        _error = 'Bluetooth non disponible en mode web';
      });
      return;
    }

    updateState(() {
      _isScanningBluetooth = true;
      _error = null;
      _success = 'Scan Bluetooth en cours... Cela peut prendre 10-15 secondes';
      _detectedPrinters = [];
      _showDetectedPrinters = false;
    });

    try {
      print('?? Starting Bluetooth printer scan...');
      
      // Vérifier que Bluetooth est disponible
      final isAvailable = await BluetoothPrinterScanner.isBluetoothAvailable();
      if (!isAvailable) {
        final hasPermission = await BluetoothPrinterScanner.requestPermissions();
        if (!hasPermission) {
          throw Exception(
            'Bluetooth non disponible. Veuillez activer Bluetooth dans les paramètres de l\'appareil.'
          );
        }
      }

      // Scanner les imprimantes Bluetooth
      final printers = await BluetoothPrinterScanner.scanForPrinters(
        scanDuration: const Duration(seconds: 10),
      );

      updateState(() {
        _detectedPrinters = printers;
        _showDetectedPrinters = true;
        if (printers.isEmpty) {
          _error = 'Aucune imprimante Bluetooth détectée.\n\n'
                   'Vérifiez que:\n'
                   '• Bluetooth est activé sur l\'appareil\n'
                   '• L\'imprimante est allumée et en mode appairage\n'
                   '• L\'imprimante est à portée (moins de 10 mètres)\n'
                   '• Les permissions Bluetooth sont accordées';
          _success = null;
        } else {
          _success = '${printers.length} imprimante(s) Bluetooth détectée(s)';
        }
        _isScanningBluetooth = false;
      });

      print('? Bluetooth scan completed: ${printers.length} printer(s) found');
    } catch (e) {
      print('? Error during Bluetooth scan: $e');
      updateState(() {
        _error = 'Erreur lors du scan Bluetooth:\n${e.toString()}\n\n'
                 'Vérifiez que Bluetooth est activé et que les permissions sont accordées.';
        _success = null;
        _isScanningBluetooth = false;
      });
    }
  }

  /// Teste la connexion à une imprimante sans imprimer
  Future<void> _testConnection(RestaurantPrinter printer) async {
    _safeSetState(() {
      _testingConnections[printer.id] = true;
      _connectionStatus[printer.id] = null;
    });

    try {
      if (printer.connectionType == 'bluetooth') {
        // Test Bluetooth
        if (printer.bluetoothDeviceId == null) {
          throw Exception('ID du périphérique Bluetooth manquant');
        }
        final isConnected = await BluetoothPrinterScanner.testBluetoothConnection(
          printer.bluetoothDeviceId!,
        );
        _safeSetState(() {
          _connectionStatus[printer.id] = isConnected;
        });
      } else if (printer.connectionType == 'usb') {
        // Test USB
        final deviceId = printer.ip;
        if (deviceId.isEmpty) {
          throw Exception('Identifiant USB manquant');
        }
        final isConnected = await UsbPrinterScanner.testUsbConnection(deviceId);
        _safeSetState(() {
          _connectionStatus[printer.id] = isConnected;
        });
      } else {
        // Test réseau
        final isAccessible = await LocalPrintService.isPrinterAccessible(printer);
        _safeSetState(() {
          _connectionStatus[printer.id] = isAccessible;
        });
      }
    } catch (e) {
      print('? Erreur test connexion ${printer.name}: $e');
      _safeSetState(() {
        _connectionStatus[printer.id] = false;
      });
    } finally {
      _safeSetState(() {
        _testingConnections[printer.id] = false;
      });
    }
  }

  /// Construit le bouton de test de connexion (vert)
  Widget _buildConnectionTestButton(RestaurantPrinter printer) {
    final isTesting = _testingConnections[printer.id] ?? false;
    final status = _connectionStatus[printer.id];
    
    Color buttonColor = Colors.green;
    IconData iconData = Icons.check_circle;
    String tooltip = 'Tester la connexion';
    
    if (isTesting) {
      buttonColor = Colors.grey;
      iconData = Icons.hourglass_empty;
      tooltip = 'Test en cours...';
    } else if (status == true) {
      buttonColor = Colors.green;
      iconData = Icons.check_circle;
      tooltip = 'Connexion OK';
    } else if (status == false) {
      buttonColor = Colors.red;
      iconData = Icons.error;
      tooltip = 'Connexion échouée';
    }
    
    return IconButton(
      icon: isTesting
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
              ),
            )
          : Icon(iconData, size: 18),
      onPressed: isTesting ? null : () => _testConnection(printer),
      tooltip: tooltip,
      color: buttonColor,
    );
  }

  String? _getSelectedPrinterId(String type) {
    switch (type) {
      case 'caisse':
        return _selectedCaissePrinterId;
      case 'cuisine':
        return _selectedCuisinePrinterId;
      case 'general':
        return _selectedGeneralPrinterId;
      default:
        return null;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'caisse':
        return 'Caisse';
      case 'cuisine':
        return 'Cuisine';
      case 'general':
        return 'Général';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'caisse':
        return Colors.green;
      case 'cuisine':
        return Colors.orange;
      case 'general':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPrinterSelector(String type) {
    final selectedId = _getSelectedPrinterId(type);
    final typePrinters = _printers.where((p) => 
      p.isEnabled && (p.type == type || (type == 'general' && p.type == 'general'))
    ).toList();

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: _getTypeColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: TawsilSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket ${_getTypeLabel(type)}',
                        style: TawsilTextStyles.headingMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Sélectionnez l\'imprimante pour les tickets ${_getTypeLabel(type).toLowerCase()}',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: TawsilColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TawsilSpacing.md),
            if (typePrinters.isEmpty)
              Container(
                padding: const EdgeInsets.all(TawsilSpacing.md),
                decoration: BoxDecoration(
                  color: TawsilColors.background,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  border: Border.all(color: TawsilColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: TawsilColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: Text(
                        'Aucune imprimante ${_getTypeLabel(type).toLowerCase()} disponible',
                        style: TawsilTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  RadioListTile<String?>(
                    title: const Text('Aucune (désactiver)'),
                    value: null,
                    groupValue: selectedId,
                    onChanged: (value) => _savePrinterSelection(type, value),
                    activeColor: TawsilColors.primary,
                  ),
                  ...typePrinters.map((printer) {
                    return RadioListTile<String?>(
                      title: Text(printer.name),
                      subtitle: Text(
                        '${printer.ip}:${printer.port} • ${printer.paperWidthMm}mm',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: TawsilColors.textSecondary,
                        ),
                      ),
                      value: printer.id,
                      groupValue: selectedId,
                      onChanged: (value) => _savePrinterSelection(type, value),
                      activeColor: TawsilColors.primary,
                      secondary: IconButton(
                        icon: const Icon(Icons.print, size: 20),
                        onPressed: () => _testPrinter(printer),
                        tooltip: 'Tester l\'imprimante',
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrowScreen = MediaQuery.of(context).size.width < 380;
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
          'Configuration des Imprimantes',
          style: TawsilTextStyles.headingMedium,
        ),
        actions: _buildAppBarActions(isNarrowScreen),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TawsilSpacing.md),
                color: TawsilColors.error.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: TawsilColors.error),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TawsilTextStyles.bodyMedium.copyWith(
                          color: TawsilColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_success != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TawsilSpacing.md),
                color: TawsilColors.success.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: TawsilColors.success),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: Text(
                        _success!,
                        style: TawsilTextStyles.bodyMedium.copyWith(
                          color: TawsilColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Contenu
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadPrinters,
                      child: ListView(
                        padding: const EdgeInsets.all(TawsilSpacing.md),
                        children: [
                          // Liste des imprimantes disponibles
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 420;
                              final actions = Wrap(
                                spacing: TawsilSpacing.sm,
                                runSpacing: TawsilSpacing.xs,
                                children: [
                                  TextButton.icon(
                                    onPressed: _scanForPrinters,
                                    icon: const Icon(Icons.search, size: 18),
                                    label: const Text('Scanner'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: TawsilColors.primary,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _openCreatePrinterDialog,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ajouter'),
                                  ),
                                ],
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Imprimantes Disponibles',
                                      style: TawsilTextStyles.headingSmall,
                                    ),
                                    const SizedBox(height: TawsilSpacing.sm),
                                    actions,
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Imprimantes Disponibles',
                                    style: TawsilTextStyles.headingSmall,
                                  ),
                                  actions,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: TawsilSpacing.sm),
                          
                          // Imprimantes détectées
                          if (_showDetectedPrinters && _detectedPrinters.isNotEmpty) ...[
                            Card(
                              elevation: 2,
                              color: TawsilColors.success.withOpacity(0.1),
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
                                          'Imprimantes Détectées (${_detectedPrinters.length})',
                                          style: TawsilTextStyles.headingSmall.copyWith(
                                            color: TawsilColors.success,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            _safeSetState(() {
                                              _showDetectedPrinters = false;
                                            });
                                          },
                                          child: const Text('Masquer'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: TawsilSpacing.sm),
                                    ..._detectedPrinters.map((printer) {
                                      final confidence = printer['confidence'] ?? 'medium';
                                      final type = printer['type'] ?? 'unknown';
                                      final ip = printer['ip'] ?? '';
                                      final name = printer['name'] ?? ip;
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.print,
                                            color: confidence == 'high' 
                                                ? TawsilColors.success 
                                                : confidence == 'medium'
                                                    ? Colors.orange
                                                    : Colors.grey,
                                          ),
                                          title: Text(name),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('$type • $ip'),
                                              if (printer['responseTime'] != null)
                                                Text('Temps de réponse: ${printer['responseTime']}ms'),
                                              if (confidence != 'high')
                                                Text(
                                                  'Confiance: ${confidence == 'medium' ? 'Moyenne' : 'Faible'}',
                                                  style: TawsilTextStyles.bodySmall.copyWith(
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline),
                                                onPressed: () => _useDetectedPrinter(printer),
                                                tooltip: 'Utiliser cette imprimante',
                                                color: TawsilColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.md),
                          ],
                          
                          if (_printers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(TawsilSpacing.lg),
                              decoration: BoxDecoration(
                                color: TawsilColors.background,
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                border: Border.all(color: TawsilColors.border),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.print_disabled,
                                    size: 48,
                                    color: TawsilColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: TawsilSpacing.sm),
                                  Text(
                                    'Aucune imprimante configurée',
                                    style: TawsilTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: TawsilSpacing.xs),
                                  Text(
                                    'Ajoutez une imprimante pour imprimer les tickets',
                                    style: TawsilTextStyles.bodySmall.copyWith(
                                      color: TawsilColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._printers.map((printer) {
                              return _buildPrinterCard(printer);
                            }),
                          const SizedBox(height: TawsilSpacing.lg),

                          // Sélecteurs par type
                          Text(
                            'Sélection des Imprimantes par Type',
                            style: TawsilTextStyles.headingSmall,
                          ),
                          const SizedBox(height: TawsilSpacing.md),
                          _buildPrinterSelector('caisse'),
                          const SizedBox(height: TawsilSpacing.md),
                          _buildPrinterSelector('cuisine'),
                          const SizedBox(height: TawsilSpacing.md),
                          _buildPrinterSelector('general'),
                          const SizedBox(height: TawsilSpacing.lg),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterModalDialog() {
    _isPrinterDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: !_isCreatingPrinter,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildPrinterModal(setModalState),
      ),
    ).then((_) {
      _isPrinterDialogOpen = false;
    });
  }


  Future<void> _savePrinter() async {
    if (_isCreatingPrinter) return;
    if (!_printerFormKey.currentState!.validate()) return;

    _safeSetState(() {
      _isCreatingPrinter = true;
      _printerFormError = null;
    });

    try {
      String ip = _printerFormIp.trim();
      final connectionType = _deriveConnectionTypeFromForm(ip, _printerFormConnectionType);
      int port = int.tryParse(_printerFormPort.trim()) ??
          (connectionType == 'bluetooth' ? 0 : 9100);
      if (connectionType == 'usb' && !ip.toUpperCase().startsWith('USB:')) {
        ip = 'USB:$ip';
      }
      if (connectionType == 'bluetooth' || connectionType == 'usb' || connectionType == 'windows') {
        port = 0;
      }
      
      String? bluetoothDeviceId;
      String? bluetoothDeviceName;
      int? usbVendorId;
      int? usbProductId;
      String? usbVendorName;
      
      if (connectionType == 'bluetooth') {
        bluetoothDeviceId = ip;
        Map<String, dynamic>? detected;
        for (final p in _detectedPrinters) {
          if (p['deviceId'] == ip) { detected = p; break; }
        }
        bluetoothDeviceName = detected?['name'] as String?;
      } else if (connectionType == 'usb') {
        final match = RegExp(r'^USB:([0-9a-fA-F]+):([0-9a-fA-F]+)$', caseSensitive: false).firstMatch(ip);
        if (_usbIdMode == 'vidpid' && match != null) {
          usbVendorId = int.parse(match.group(1)!, radix: 16);
          usbProductId = int.parse(match.group(2)!, radix: 16);
          Map<String, dynamic>? detected;
          for (final p in _detectedPrinters) {
            if (p['deviceId'] == ip) { detected = p; break; }
          }
          usbVendorName = detected?['manufacturer'] as String?;
        } else {
          // Fallback to Windows name/port when VID:PID isn't provided
          final normalized = ip.replaceFirst(RegExp(r'^USB:', caseSensitive: false), '').trim();
          if (normalized.isEmpty) {
            throw Exception('Nom USB invalide');
          }
          usbVendorName = _selectedUsbDetectedPrinter?['manufacturer'] as String? ?? normalized;
          usbVendorId = _selectedUsbDetectedPrinter?['vendorId'] as int?;
          usbProductId = _selectedUsbDetectedPrinter?['productId'] as int?;
        }
      }

      final restaurantId = await _apiService.getRestaurantId();
      if (restaurantId == null) {
        throw Exception('Restaurant ID non trouvé');
      }

      if (_editingPrinter == null) {
        // Créer
        await _apiService.createPrinter(
          restaurantId: restaurantId,
          name: _printerFormName.trim(),
          type: _printerFormType,
          connectionType: connectionType,
          ip: ip,
          port: port,
          bluetoothDeviceId: bluetoothDeviceId,
          bluetoothDeviceName: bluetoothDeviceName,
          usbVendorId: usbVendorId,
          usbProductId: usbProductId,
          usbVendorName: usbVendorName,
          isEnabled: _printerFormEnabled,
          paperWidthMm: int.parse(_printerFormPaperWidth),
        );
        _safeSetState(() {
          _success = 'Imprimante créée avec succès';
        });
      } else {
        // Modifier
        await _apiService.updatePrinter(
          printerId: _editingPrinter!.id,
          name: _printerFormName.trim(),
          type: _printerFormType,
          connectionType: connectionType,
          ip: ip,
          port: port,
          bluetoothDeviceId: bluetoothDeviceId,
          bluetoothDeviceName: bluetoothDeviceName,
          usbVendorId: usbVendorId,
          usbProductId: usbProductId,
          usbVendorName: usbVendorName,
          isEnabled: _printerFormEnabled,
          paperWidthMm: int.parse(_printerFormPaperWidth),
        );
        _safeSetState(() {
          _success = 'Imprimante modifiée avec succès';
        });
      }

      // Recharger et fermer
      await _loadPrinters();
      await _printService.invalidatePrintersCache();
      
      if (mounted) {
        Navigator.of(context).pop();
        _safeSetState(() {
          _editingPrinter = null;
        });
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _safeSetState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      final msg = 'Erreur: ${e.toString()}';
      _safeSetState(() {
        _printerFormError = msg;
        _isCreatingPrinter = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) _safeSetState(() => _isCreatingPrinter = false);
    }
  }

  /// Confirme et supprime une imprimante
  Future<void> _confirmDeletePrinter(BuildContext context, RestaurantPrinter printer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'imprimante'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'imprimante "${printer.name}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    _safeSetState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await _apiService.deletePrinter(printer.id);
      
      _safeSetState(() {
        _success = 'Imprimante "${printer.name}" supprimée avec succès';
      });

      // Recharger la liste des imprimantes
      await _loadPrinters();
      await _printService.invalidatePrintersCache();

      // Masquer le message de succès après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _safeSetState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      _safeSetState(() {
        _error = 'Erreur lors de la suppression: ${e.toString()}';
      });
    } finally {
      _safeSetState(() {
        _loading = false;
      });
    }
  }

  Future<void> _clearPrinterSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_caisse_printer_id');
    await prefs.remove('selected_cuisine_printer_id');
    await prefs.remove('selected_general_printer_id');
    if (mounted) {
      _safeSetState(() {
        _selectedCaissePrinterId = null;
        _selectedCuisinePrinterId = null;
        _selectedGeneralPrinterId = null;
      });
    }
  }

  /// Confirme et supprime toutes les imprimantes
  Future<void> _confirmDeleteAllPrinters(BuildContext context) async {
    if (_printers.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les imprimantes'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer toutes les imprimantes (${_printers.length}) ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    _safeSetState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    int deletedCount = 0;
    final errors = <String>[];
    final printersToDelete = List<RestaurantPrinter>.from(_printers);

    try {
      for (final printer in printersToDelete) {
        try {
          await _apiService.deletePrinter(printer.id);
          deletedCount++;
        } catch (e) {
          errors.add('${printer.name}: ${e.toString()}');
        }
      }

      await _clearPrinterSelections();
      await _loadPrinters();
      await _printService.invalidatePrintersCache();

      if (deletedCount > 0) {
        _success = '$deletedCount imprimante(s) supprimée(s) avec succès';
      }
      if (errors.isNotEmpty) {
        _error = 'Suppression partielle: ${errors.length} échec(s).';
        for (final err in errors) {
          print('? Delete printer error: $err');
        }
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _safeSetState(() {
            _success = null;
          });
        }
      });
    } finally {
      if (mounted) {
        _safeSetState(() {
          _loading = false;
        });
      }
    }
  }

  /// Génère un ID USB aléatoire au format USB:vid:pid (4 chiffres hex chacun).
  /// Utile pour tests ou démo. L'impression ne fonctionnera que si un périphérique
  /// avec ce VID:PID est réellement connecté.
  void _generateRandomUsbId({StateSetter? setModalState}) {
    final updateState = (VoidCallback fn) => _safeModalSetState(setModalState, fn);
    updateState(() {
      final r = Random();
      final vid = r.nextInt(0x10000).toRadixString(16).padLeft(4, '0').toLowerCase();
      final pid = r.nextInt(0x10000).toRadixString(16).padLeft(4, '0').toLowerCase();
      _applyUsbIdFieldValue('USB:$vid:$pid');
    });
  }

  void _applyUsbIdFieldValue(String value) {
    _printerFormIp = value;
    _usbIdFormVersion++;
    _printerFormVersion++;
  }

  void _selectDetectedUsbPrinter(
    Map<String, dynamic> printer,
    StateSetter setModalState,
  ) {
    _safeModalSetState(setModalState, () {
      final n = printer['name'] as String?;
      if (n != null && n.trim().isNotEmpty) _printerFormName = n.trim();
      _applyUsbIdFieldValue(_formatUsbIdFromDetected(printer));
      _printerFormPort = '0';
      _selectedUsbDetectedPrinter = printer;
      _printerFormVersion++;
    });
  }

  String _formatUsbIdFromDetected(Map<String, dynamic> printer) {
    final deviceId = printer['deviceId'] as String? ?? '';
    if (_usbIdMode == 'name') {
      final deviceName = (printer['deviceName'] as String?) ??
          (printer['name'] as String?);
      if (deviceName != null && deviceName.trim().isNotEmpty) {
        final cleanedName = deviceName.trim().replaceFirst(RegExp(r'^USB:', caseSensitive: false), '');
        if (cleanedName.isNotEmpty) {
          return 'USB:$cleanedName';
        }
      }
    }
    return deviceId;
  }

  Widget _buildPrinterModal(StateSetter setModalState) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.vertical - (TawsilSpacing.md * 2);
    final dialogHeight = max(0.0, availableHeight);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.md,
        vertical: TawsilSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.xl),
      ),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: dialogHeight,
          ),
          decoration: BoxDecoration(
            color: TawsilColors.surface,
            borderRadius: BorderRadius.circular(TawsilBorderRadius.xl),
          ),
          child: Form(
            key: _printerFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(TawsilSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: TawsilColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _editingPrinter == null ? Icons.add : Icons.edit,
                        color: TawsilColors.primary,
                      ),
                      const SizedBox(width: TawsilSpacing.sm),
                      Expanded(
                        child: Text(
                          _editingPrinter == null
                              ? 'Nouvelle Imprimante'
                              : 'Modifier l\'Imprimante',
                          style: TawsilTextStyles.headingMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _isCreatingPrinter
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(TawsilSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          if (_printerFormError != null)
                            Container(
                              padding: const EdgeInsets.all(TawsilSpacing.sm),
                              margin: const EdgeInsets.only(bottom: TawsilSpacing.md),
                              decoration: BoxDecoration(
                                color: TawsilColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                border: Border.all(color: TawsilColors.error),
                              ),
                              child: Text(
                                _printerFormError!,
                                style: TawsilTextStyles.bodySmall.copyWith(
                                  color: TawsilColors.error,
                                ),
                              ),
                            ),
                          // Nom
                          TextFormField(
                            key: ValueKey('printer_name_v$_printerFormVersion'),
                            initialValue: _printerFormName,
                            decoration: InputDecoration(
                              labelText: 'Nom *',
                              hintText: 'Ex: Caisse 1, Cuisine',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                              ),
                            ),
                            onChanged: (value) => _printerFormName = value,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Le nom est requis' : null,
                          ),
                          const SizedBox(height: TawsilSpacing.md),
                          // Type
                          DropdownButtonFormField<String>(
                            value: _printerFormType,
                            decoration: InputDecoration(
                              labelText: 'Type de ticket *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'general', child: Text('Général')),
                              DropdownMenuItem(value: 'caisse', child: Text('Caisse')),
                              DropdownMenuItem(value: 'cuisine', child: Text('Cuisine')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  _printerFormType = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: TawsilSpacing.md),
                          // Type de connexion
                          DropdownButtonFormField<String>(
                            value: _printerFormConnectionType,
                            decoration: InputDecoration(
                              labelText: 'Type de connexion *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'network',
                                child: Text('Réseau (IP + port)'),
                              ),
                              if (!kIsWeb) ...[
                                const DropdownMenuItem(
                                  value: 'usb',
                                  child: Text('USB'),
                                ),
                                const DropdownMenuItem(
                                  value: 'bluetooth',
                                  child: Text('Bluetooth'),
                                ),
                              ],
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  _printerFormConnectionType = value;
                                  _selectedUsbDetectedPrinter = null;
                                  if (value == 'bluetooth' || value == 'usb') {
                                    _printerFormIp = '';
                                    _printerFormPort = '0';
                                  }
                                  if (value == 'usb') {
                                    // Default to Windows name/port to avoid forcing VID:PID
                                    _usbIdMode = 'name';
                                  } else if (value == 'network' &&
                                      (_printerFormPort.trim().isEmpty || _printerFormPort == '0')) {
                                    _printerFormPort = '9100';
                                  } else {
                                    _usbIdMode = 'vidpid';
                                  }
                                  _printerFormVersion++;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: TawsilSpacing.md),
                          
                          // Champs selon le type de connexion
                          if (_printerFormConnectionType == 'network') ...[
                            // Champs réseau
                            TextFormField(
                              key: ValueKey('printer_ip_v$_printerFormVersion'),
                              initialValue: _printerFormIp,
                              decoration: InputDecoration(
                                labelText: 'Adresse IP *',
                                hintText: '192.168.1.100',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                ),
                              ),
                              onChanged: (value) => _printerFormIp = value,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'L\'IP est requise' : null,
                            ),
                            const SizedBox(height: TawsilSpacing.md),
                            TextFormField(
                              key: ValueKey('printer_port_v$_printerFormVersion'),
                              initialValue: _printerFormPort,
                              decoration: InputDecoration(
                                labelText: 'Port *',
                                hintText: '9100',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                ),
                                helperText: 'Port standard: 9100 (RAW) pour l\'impression ESC/POS',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _printerFormPort = value,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Le port est requis';
                                final port = int.tryParse(value!);
                                if (port == null || port < 1 || port > 65535) {
                                  return 'Port invalide (1-65535)';
                                }
                                return null;
                              },
                            ),
                          ] else if (_printerFormConnectionType == 'bluetooth') ...[
                            // Bouton pour scanner Bluetooth
                            ElevatedButton.icon(
                              onPressed: () => _scanBluetoothPrinters(setModalState: setModalState),
                              icon: const Icon(Icons.bluetooth),
                              label: const Text('Scanner les imprimantes Bluetooth'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TawsilColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TawsilSpacing.md,
                                  vertical: TawsilSpacing.sm,
                                ),
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.sm),
                            Text(
                              'Sélectionnez une imprimante Bluetooth détectée ci-dessus, ou entrez manuellement l\'ID du périphérique.',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.md),
                            // Liste des imprimantes Bluetooth détectées
                            if (_detectedPrinters.any((p) => p['connectionType'] == 'bluetooth'))
                              ..._detectedPrinters
                                  .where((p) => p['connectionType'] == 'bluetooth')
                                  .map((printer) => Card(
                                        margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
                                        child: ListTile(
                                          leading: const Icon(Icons.bluetooth, color: Colors.blue),
                                          title: Text(printer['name'] ?? 'Imprimante inconnue'),
                                          subtitle: Text('ID: ${printer['deviceId']}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.check_circle),
                                            onPressed: () {
                                              setModalState(() {
                                                final n = printer['name'] as String?;
                                                if (n != null && n.trim().isNotEmpty) {
                                                  _printerFormName = n.trim();
                                                }
                                                _printerFormIp = (printer['deviceId'] as String?) ?? '';
                                                _printerFormPort = '0';
                                                _selectedUsbDetectedPrinter = null;
                                                _printerFormVersion++;
                                              });
                                            },
                                          ),
                                        ),
                                      )),
                            const SizedBox(height: TawsilSpacing.md),
                            TextFormField(
                              key: ValueKey('printer_bt_v$_printerFormVersion'),
                              initialValue: _printerFormIp,
                              decoration: InputDecoration(
                                labelText: 'ID du périphérique Bluetooth *',
                                hintText: 'Ex: 00:11:22:33:44:55',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                ),
                                helperText: 'ID du périphérique Bluetooth (adresse MAC)',
                              ),
                              onChanged: (value) => _printerFormIp = value,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'L\'ID Bluetooth est requis' : null,
                            ),
                          ] else if (_printerFormConnectionType == 'usb') ...[
                            // Bouton pour scanner USB
                            ElevatedButton.icon(
                              onPressed: () => _scanUsbPrinters(setModalState: setModalState),
                              icon: const Icon(Icons.usb),
                              label: const Text('Scanner les imprimantes USB'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TawsilColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TawsilSpacing.md,
                                  vertical: TawsilSpacing.sm,
                                ),
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.sm),
                            Text(
                              'Sélectionnez une imprimante USB détectée ci-dessus, ou entrez manuellement les IDs USB.',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.md),
                            // Liste des imprimantes USB détectées
                            if (_detectedPrinters.any((p) => p['connectionType'] == 'usb'))
                              ..._detectedPrinters
                                  .where((p) => p['connectionType'] == 'usb')
                                  .map((printer) {
                                    final deviceId = printer['deviceId'] as String?;
                                    final selectedDeviceId =
                                        _selectedUsbDetectedPrinter?['deviceId'] as String?;
                                    final portName = printer['portName'] as String?;
                                    final portText = (portName != null && portName.trim().isNotEmpty)
                                        ? ' • Port: ${portName.trim()}'
                                        : '';
                                    final isSelected = deviceId != null &&
                                            selectedDeviceId != null &&
                                            deviceId == selectedDeviceId ||
                                        identical(_selectedUsbDetectedPrinter, printer);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
                                      child: ListTile(
                                        leading: const Icon(Icons.usb, color: Colors.orange),
                                        title: Text(printer['name'] ?? 'Imprimante USB'),
                                        subtitle: Text(
                                          'Vendor: ${(printer['vendorId'] as int?)?.toRadixString(16) ?? 'N/A'}, '
                                          'Product: ${(printer['productId'] as int?)?.toRadixString(16) ?? 'N/A'}$portText',
                                        ),
                                        selected: isSelected,
                                        selectedTileColor:
                                            TawsilColors.primaryLight.withOpacity(0.12),
                                        onTap: () => _selectDetectedUsbPrinter(
                                          printer,
                                          setModalState,
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? TawsilColors.primary
                                                : TawsilColors.textSecondary,
                                          ),
                                          onPressed: () => _selectDetectedUsbPrinter(
                                            printer,
                                            setModalState,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            const SizedBox(height: TawsilSpacing.md),
                            Text(
                              'Identifiant USB préféré',
                              style: TawsilTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.xs),
                            Wrap(
                              spacing: TawsilSpacing.sm,
                              runSpacing: TawsilSpacing.xs,
                              children: [
                                ChoiceChip(
                                  label: const Text('VID:PID (stable)'),
                                  selected: _usbIdMode == 'vidpid',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() {
                                        _usbIdMode = 'vidpid';
                                        if (_selectedUsbDetectedPrinter != null) {
                                          _applyUsbIdFieldValue(
                                            _formatUsbIdFromDetected(_selectedUsbDetectedPrinter!),
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Nom Windows'),
                                  selected: _usbIdMode == 'name',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() {
                                        _usbIdMode = 'name';
                                        if (_selectedUsbDetectedPrinter != null) {
                                          _applyUsbIdFieldValue(
                                            _formatUsbIdFromDetected(_selectedUsbDetectedPrinter!),
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: TawsilSpacing.md),
                            Text(
                              _usbIdMode == 'vidpid'
                                  ? 'Utilisez le pair VendorID:ProductID tel que détecté dans Windows.'
                                  : 'Utilisez exactement le nom affiché dans le Gestionnaire de périphériques, ou un port Windows (USB001/COM3/LPT1).',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: TawsilSpacing.md),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 360;
                                final usbIdField = TextFormField(
                                  key: ValueKey('usb_id_v$_usbIdFormVersion'),
                                  initialValue: _printerFormIp,
                                  decoration: InputDecoration(
                                    labelText: 'ID du périphérique USB *',
                                    hintText: 'USB:04f9:2042',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                    ),
                                    helperText: _usbIdMode == 'vidpid'
                                        ? 'Format: USB:vendorId:productId (ex: USB:04f9:2042)'
                                        : 'Format: USB:Nom Windows, ou USB:USB001/COM3/LPT1',
                                  ),
                                  onChanged: (value) {
                                    _printerFormIp = value ?? '';
                                    _selectedUsbDetectedPrinter = null;
                                  },
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'L\'ID USB est requis';
                                    final normalized = value!.trim();
                                    if (!normalized.toUpperCase().startsWith('USB:')) {
                                      return 'Commencez par "USB:"';
                                    }
                                    final displayName = normalized.substring(4).trim();
                                    if (displayName.isEmpty) {
                                      return _usbIdMode == 'vidpid'
                                          ? 'Format invalide. Utilisez: USB:vendorId:productId'
                                          : 'Entrez le nom affiché dans Windows';
                                    }
                                    return null;
                                  },
                                );
                                final randomButton = OutlinedButton.icon(
                                  onPressed: _usbIdMode == 'vidpid'
                                      ? () => _generateRandomUsbId(setModalState: setModalState)
                                      : null,
                                  icon: const Icon(Icons.shuffle, size: 18),
                                  label: const Text('Aléatoire'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TawsilColors.primary,
                                  ),
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      usbIdField,
                                      const SizedBox(height: TawsilSpacing.sm),
                                      randomButton,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: usbIdField),
                                    const SizedBox(width: TawsilSpacing.sm),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: randomButton,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: TawsilSpacing.xs),
                            Text(
                              '« Aléatoire » remplit un VID:PID aléatoire (tests/démo). '
                              'L\'impression fonctionne seulement si un périphérique avec cet ID est connecté.',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          // Message d'aide pour les imprimantes avec interface web
                          if (_printerFormPort == '80' || _printerFormPort.isEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: TawsilSpacing.sm),
                              padding: const EdgeInsets.all(TawsilSpacing.sm),
                              decoration: BoxDecoration(
                                color: TawsilColors.primaryLight.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                border: Border.all(color: TawsilColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: TawsilColors.primary,
                                  ),
                                  const SizedBox(width: TawsilSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'Pour les imprimantes avec interface web (port 80), utilisez généralement le port 9100 pour l\'impression ESC/POS. '
                                      'Si 9100 ne fonctionne pas, essayez 9101.',
                                      style: TawsilTextStyles.bodySmall.copyWith(
                                        color: TawsilColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: TawsilSpacing.md),
                          // Largeur papier
                          DropdownButtonFormField<String>(
                            value: _printerFormPaperWidth,
                            decoration: InputDecoration(
                              labelText: 'Largeur papier *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: '58', child: Text('58 mm')),
                              DropdownMenuItem(value: '80', child: Text('80 mm')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  _printerFormPaperWidth = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: TawsilSpacing.md),
                          // Activé
                          CheckboxListTile(
                            title: const Text('Imprimante activée'),
                            subtitle: const Text('Impression automatique à chaque commande'),
                            value: _printerFormEnabled,
                            onChanged: (value) {
                              setModalState(() {
                                _printerFormEnabled = value ?? true;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),
              // Footer
              Container(
                padding: const EdgeInsets.all(TawsilSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: TawsilColors.border),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: TawsilSpacing.sm,
                  runSpacing: TawsilSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: _isCreatingPrinter
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: _savePrinter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TawsilColors.primary,
                      ),
                      child: _isCreatingPrinter
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_editingPrinter == null ? 'Créer' : 'Enregistrer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}




