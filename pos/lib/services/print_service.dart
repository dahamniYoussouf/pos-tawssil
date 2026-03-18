// lib/services/print_service.dart
import 'dart:async';
import '../models/order.dart';
import '../models/restaurant_printer.dart';
import '../services/api_service.dart';
import '../services/local_print_service.dart';
import '../services/print_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Status class for print operations
class PrintStatus {
  final bool isPrinting;
  final String? lastError;
  final bool lastSuccess;
  final int queueLength;
  final String? currentPrinter;

  PrintStatus({
    this.isPrinting = false,
    this.lastError,
    this.lastSuccess = false,
    this.queueLength = 0,
    this.currentPrinter,
  });

  PrintStatus copyWith({
    bool? isPrinting,
    String? lastError,
    bool? lastSuccess,
    int? queueLength,
    String? currentPrinter,
  }) {
    return PrintStatus(
      isPrinting: isPrinting ?? this.isPrinting,
      lastError: lastError ?? this.lastError,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      queueLength: queueLength ?? this.queueLength,
      currentPrinter: currentPrinter ?? this.currentPrinter,
    );
  }
}

/// Service wrapper for printing operations
/// Provides a unified interface for printing orders and managing print status
class PrintService {
  static final PrintService _instance = PrintService._internal();

  final ApiService _apiService = ApiService();
  final PrintLogService _printLogService = PrintLogService();
  final _statusController = StreamController<PrintStatus>.broadcast();
  int _queueLength = 0;
  bool _isPrinting = false;
  String? _lastError;
  bool _lastSuccess = false;

  /// Stream of print status updates
  Stream<PrintStatus> get statusStream => _statusController.stream;

  factory PrintService() => _instance;

  PrintService._internal();

  Future<_SelectedPrinterIds> _loadSelectedPrinterIds() async {
    final prefs = await SharedPreferences.getInstance();
    return _SelectedPrinterIds(
      caisse: prefs.getString('selected_caisse_printer_id'),
      cuisine: prefs.getString('selected_cuisine_printer_id'),
      general: prefs.getString('selected_general_printer_id'),
    );
  }

  List<RestaurantPrinter> _filterPrintersBySelection(
    List<RestaurantPrinter> printers,
    _SelectedPrinterIds selected,
  ) {
    if (selected.isEmpty) return [];
    return printers.where(selected.isSelectedForPrinter).toList();
  }

  List<RestaurantPrinter> _orderCashDrawerCandidates(
    List<RestaurantPrinter> printers,
    _SelectedPrinterIds selected,
  ) {
    final byId = <String, RestaurantPrinter>{};
    for (final printer in printers) {
      byId[printer.id] = printer;
    }
    final ordered = <RestaurantPrinter>[];
    if (selected.caisse != null && byId.containsKey(selected.caisse)) {
      ordered.add(byId[selected.caisse]!);
    }
    if (selected.general != null && byId.containsKey(selected.general)) {
      ordered.add(byId[selected.general]!);
    }
    if (selected.cuisine != null && byId.containsKey(selected.cuisine)) {
      ordered.add(byId[selected.cuisine]!);
    }
    if (ordered.isNotEmpty) return ordered;
    return printers;
  }

  /// Get current print status
  PrintStatus get currentStatus => PrintStatus(
        isPrinting: _isPrinting,
        lastError: _lastError,
        lastSuccess: _lastSuccess,
        queueLength: _queueLength,
      );

  /// Print an order asynchronously
  /// This will attempt to print to configured printers
  /// Une seule impression par commande : vérification "en cours / déjà imprimée" + dédup par périphérique.
  Future<void> printOrderAsync(
    Order order, {
    Function(String)? onError,
    bool forcePrint = false, // Force l'impression même si déjà imprimée
  }) async {
    if (!forcePrint) {
      final inProgressOrDone = await _printLogService.hasOrderPrintInProgressOrDoneRecently(
        order.id,
        orderNumber: order.orderNumber,
      );
      if (inProgressOrDone) {
        _lastSuccess = true;
        _lastError = null;
        _updateStatus();
        return;
      }
    }

    final printers = await _getConfiguredPrinters();
    if (printers.isEmpty) {
      if (onError != null) {
        onError(
          'Aucune imprimante configurée.\n\n'
          '1. Allez dans Paramètres → Imprimantes\n'
          '2. Configurez au moins une imprimante',
        );
      }
      _lastError = 'Aucune imprimante configurée. Paramètres → Imprimantes.';
      _updateStatus();
      return;
    }
    final selectedIds = await _loadSelectedPrinterIds();
    final selectedPrinters = _filterPrintersBySelection(printers, selectedIds);
    if (selectedPrinters.isEmpty) {
      if (onError != null) {
        onError(
          'Aucune imprimante sélectionnée.\n\n'
          '1. Allez dans Paramètres → Imprimantes\n'
          '2. Sélectionnez une imprimante pour chaque type de ticket',
        );
      }
      _lastError = 'Aucune imprimante sélectionnée. Paramètres → Imprimantes.';
      _updateStatus();
      return;
    }

    // Marquer tout de suite "impression demandée" pour bloquer doublons (double clic)
    await _printLogService.logPrintRequested(order.id, order.orderNumber);

    _isPrinting = true;
    _lastError = null;
    _lastSuccess = false;
    _queueLength++;
    _updateStatus();

    try {
        final prefs = await SharedPreferences.getInstance();
        final restaurantName = prefs.getString('restaurant_name') ?? 'Restaurant';
        final cashierName = prefs.getString('cashier_name');
        final cashierCode = prefs.getString('cashier_code');
        final allowNetworkPrinting = prefs.getBool('allow_network_printing') ?? true;
        bool atLeastOneSuccess = false;

      // En ligne: éviter l'impression réseau si l'option est désactivée.
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;
      final isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
        final localPrinters = isOnline && !isMobilePlatform && !allowNetworkPrinting
            ? selectedPrinters.where((printer) {
                final ct = (printer.connectionType ?? '').toLowerCase();
                final isUsb = ct == 'usb' ||
                    ct == 'windows' ||
                    printer.ip.toUpperCase().startsWith('USB:');
                final isBt = ct == 'bluetooth' || printer.bluetoothDeviceId != null;
                return isUsb || isBt;
              }).toList()
            : selectedPrinters;

        if (isOnline && localPrinters.isEmpty) {
          _lastSuccess = false;
          _lastError = 'Aucune imprimante locale disponible. Activez l\'impression réseau ou configurez une imprimante locale.';
          _updateStatus();
          return;
        }

      for (final printer in localPrinters) {
        if (!printer.isEnabled) continue;

        final deviceKey = LocalPrintService.deviceKeyFor(printer);
        if (!forcePrint) {
          final alreadyPrintedToDevice = await _printLogService.hasOrderBeenPrintedToDeviceRecently(
            order.id,
            order.orderNumber,
            deviceKey,
          );
          if (alreadyPrintedToDevice) {
            continue;
          }
        }

        try {
          await LocalPrintService.printOrderDirectly(
            printer,
            order,
            restaurantName: restaurantName,
            cashierName: cashierName,
            cashierCode: cashierCode,
          );
          await _printLogService.logPrint(
            orderId: order.id,
            orderNumber: order.orderNumber,
            printer: printer,
            deviceKey: deviceKey,
            success: true,
          );
          atLeastOneSuccess = true;
        } catch (e) {
          await _printLogService.logPrint(
            orderId: order.id,
            orderNumber: order.orderNumber,
            printer: printer,
            deviceKey: deviceKey,
            success: false,
            errorMessage: e.toString(),
          );
          if (onError != null) {
            onError('Erreur lors de l\'impression sur ${printer.name}: $e');
          }
          _lastError = 'Erreur lors de l\'impression sur ${printer.name}:\n$e';
          _updateStatus();
        }
      }

      _lastSuccess = atLeastOneSuccess;
      _lastError = atLeastOneSuccess ? null : 'Aucune impression réussie';
    } catch (e) {
      _lastError = e.toString();
      if (onError != null) onError(_lastError!);
    } finally {
      _isPrinting = false;
      _queueLength = _queueLength > 0 ? _queueLength - 1 : 0;
      _updateStatus();
    }
  }

  /// Open cash drawer
  /// This will attempt to open the cash drawer on configured printers
  Future<void> openCashDrawer() async {
    try {
      final printers = await _getConfiguredPrinters();

      if (printers.isEmpty) {
        throw Exception('Aucune imprimante configurée pour ouvrir le tiroir-caisse');
      }

      final selectedIds = await _loadSelectedPrinterIds();
      final selectedPrinters = _filterPrintersBySelection(printers, selectedIds);
      if (selectedPrinters.isEmpty) {
        throw Exception('Aucune imprimante sélectionnée pour ouvrir le tiroir-caisse');
      }

      final orderedCandidates = _orderCashDrawerCandidates(selectedPrinters, selectedIds);

      // Try to open drawer on the first enabled selected printer
      for (final printer in orderedCandidates) {
        if (!printer.isEnabled) continue;

        try {
          await LocalPrintService.openCashDrawerDirectly(printer);
          return; // Success, exit
        } catch (e) {
          // Try next printer
        }
      }

      throw Exception('Impossible d\'ouvrir le tiroir-caisse sur aucune imprimante configurée');
    } catch (e) {
      rethrow;
    }
  }

  /// Invalide le cache des imprimantes (force le rechargement)
  Future<void> invalidatePrintersCache() async {
    // Le cache est géré par l'API, cette méthode permet de forcer le rechargement
  }

  /// Print an order (synchronous wrapper for printOrderAsync)
  Future<void> printOrder(Order order, {Function(String)? onError}) async {
    await printOrderAsync(order, onError: onError);
  }

  /// Get configured printers from API or local storage
  Future<List<RestaurantPrinter>> _getConfiguredPrinters() async {
    try {
      // Try to get from API first
      final printers = await _apiService.fetchRestaurantPrinters();
      if (printers.isNotEmpty) {
        return printers;
      }
    } catch (e) {
    }

    // Fallback: return empty list (user needs to configure printers)
    return [];
  }

  /// Update status and notify listeners
  void _updateStatus() {
    _statusController.add(currentStatus);
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

class _SelectedPrinterIds {
  final String? caisse;
  final String? cuisine;
  final String? general;

  const _SelectedPrinterIds({
    this.caisse,
    this.cuisine,
    this.general,
  });

  bool get isEmpty => caisse == null && cuisine == null && general == null;

  bool isSelectedForPrinter(RestaurantPrinter printer) {
    final type = printer.type.toLowerCase();
    switch (type) {
      case 'caisse':
        return caisse != null && printer.id == caisse;
      case 'cuisine':
        return cuisine != null && printer.id == cuisine;
      case 'general':
        return general != null && printer.id == general;
      default:
        return false;
    }
  }

  Set<String> asSet() {
    final ids = <String>{};
    if (caisse != null && caisse!.isNotEmpty) ids.add(caisse!);
    if (cuisine != null && cuisine!.isNotEmpty) ids.add(cuisine!);
    if (general != null && general!.isNotEmpty) ids.add(general!);
    return ids;
  }
}



