import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/restaurant_printer.dart';
import '../services/api_service.dart';
import '../services/local_print_service.dart';
import 'print_log_service.dart';

/// Service pour gérer les jobs d'impression depuis le backend
/// Le POS agit comme un bridge local pour imprimer sur le réseau local
class PrintJobService {
  final ApiService _apiService = ApiService();
  final PrintLogService _printLogService = PrintLogService();
  Timer? _pollTimer;
  bool _isPolling = false;
  bool _isProcessing = false;
  bool _isOnline = false;

  /// Démarre le polling automatique des jobs d'impression
  /// Poll toutes les 5 secondes
  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    if (_isPolling) {
      print('⚠️ Print job polling already started');
      return;
    }

    _isPolling = true;
    print('🔄 Starting print job polling (interval: ${interval.inSeconds}s)');

    // Surveiller la connectivité
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        print('🌐 Connection restored, processing pending jobs...');
        _processPendingJobs();
      } else {
        print('📴 Offline mode - will process jobs when online');
      }
    });

    // Vérifier l'état initial
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result != ConnectivityResult.none;
    });

    _pollTimer = Timer.periodic(interval, (_) async {
      if (!_isProcessing && _isOnline) {
        await _processPendingJobs();
      }
    });

    // Traiter immédiatement au démarrage si online
    if (_isOnline) {
      _processPendingJobs();
    }
  }

  /// Arrête le polling
  void stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    print('⏹️ Print job polling stopped');
  }

  /// Traite les jobs d'impression en attente
  Future<void> _processPendingJobs() async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      // Récupérer les jobs en attente
      final jobs = await _apiService.getPendingPrintJobs();

      if (jobs.isEmpty) {
        _isProcessing = false;
        return;
      }

      print('📋 Found ${jobs.length} pending print job(s)');

      // Traiter chaque job
      for (final job in jobs) {
        try {
          await _processJob(job);
        } catch (e) {
          print('❌ Error processing job ${job['id']}: $e');
          // Marquer comme échoué
          await _apiService.completePrintJob(
            jobId: job['id'],
            success: false,
            errorMessage: e.toString(),
          );
        }
      }
    } catch (e) {
      print('❌ Error fetching pending jobs: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Traite un job d'impression individuel
  Future<void> _processJob(Map<String, dynamic> job) async {
    final jobId = job['id'] as String;
    print('🖨️ Processing print job: $jobId');

    RestaurantPrinter? printer;
    Order? order;

    try {
      // Réclamer le job (marquer comme en cours de traitement)
      final claimedJob = await _apiService.claimPrintJob(jobId);
      
      final printerData = claimedJob['printer'] as Map<String, dynamic>;
      final orderData = claimedJob['order'] as Map<String, dynamic>;

      // Convertir en objets
      printer = RestaurantPrinter.fromJson(printerData);
      order = _convertOrderData(orderData);

      // ✅ VÉRIFIER SI LA COMMANDE A DÉJÀ ÉTÉ IMPRIMÉE RÉCEMMENT
      final alreadyPrinted = await _printLogService.hasOrderBeenPrintedRecently(order.id);
      if (alreadyPrinted) {
        print('⚠️ Order #${order.orderNumber} was already printed recently. Skipping job $jobId to avoid duplicate.');
        
        // Marquer le job comme complété même si on ne l'imprime pas (pour éviter les retentatives)
        if (_isOnline) {
          try {
            await _apiService.completePrintJob(
              jobId: jobId,
              success: true,
            );
            print('✅ Print job $jobId marked as completed (already printed)');
          } catch (e) {
            print('⚠️ Failed to mark job as complete: $e');
          }
        }
        return; // Sortir sans imprimer
      }

      // Récupérer le nom du restaurant
      final restaurantName = orderData['restaurant']?['name'] ?? 'Restaurant';
      
      // Récupérer les infos du caissier
      final cashierName = orderData['cashier']?['name'] ?? 
                         orderData['created_by_cashier']?['name'];
      final cashierCode = orderData['cashier']?['cashier_code'] ?? 
                         orderData['created_by_cashier']?['cashier_code'];

      // Imprimer localement (fonctionne même offline)
      await LocalPrintService.printOrderDirectly(
        printer,
        order,
        restaurantName: restaurantName,
        cashierName: cashierName,
        cashierCode: cashierCode,
      );

      // Enregistrer le log localement
      await _printLogService.logPrint(
        orderId: order.id,
        printer: printer,
        success: true,
      );

      // Marquer comme complété (si online)
      if (_isOnline) {
        try {
          await _apiService.completePrintJob(
            jobId: jobId,
            success: true,
          );
        } catch (e) {
          print('⚠️ Failed to mark job as complete (will retry): $e');
          // Le job sera retraité au prochain poll
        }
      } else {
        print('📴 Offline - job completion will be synced when online');
      }

      print('✅ Print job $jobId completed successfully');
    } catch (e) {
      print('❌ Error processing print job $jobId: $e');
      
      // Enregistrer l'échec dans les logs locaux (si on a les données)
      if (order != null) {
        await _printLogService.logPrint(
          orderId: order.id,
          printer: printer,
          success: false,
          errorMessage: e.toString(),
        );
      }
      
      // Marquer comme échoué (si online)
      if (_isOnline) {
        try {
          await _apiService.completePrintJob(
            jobId: jobId,
            success: false,
            errorMessage: e.toString(),
          );
        } catch (syncError) {
          print('⚠️ Failed to mark job as failed (will retry): $syncError');
        }
      } else {
        print('📴 Offline - job failure will be synced when online');
      }
      
      rethrow;
    }
  }

  /// Convertit les données de commande en objet Order
  Order _convertOrderData(Map<String, dynamic> orderData) {
    // Convertir les order_items
    final items = (orderData['order_items'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Order(
      id: orderData['id'] as String,
      orderNumber: (orderData['order_number'] as String?) ?? '',
      cashierId: (orderData['created_by_cashier_id'] as String?) ?? '',
      restaurantId: (orderData['restaurant_id'] as String?) ?? '',
      orderType: (orderData['order_type'] as String?) ?? 'pickup',
      subtotal: (orderData['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (orderData['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (orderData['payment_method'] as String?) ?? 'cash',
      status: orderData['status'] as String? ?? 'pending',
      items: items,
      createdAt: orderData['created_at'] != null
          ? DateTime.parse(orderData['created_at'])
          : DateTime.now(),
      updatedAt: orderData['updated_at'] != null
          ? DateTime.parse(orderData['updated_at'])
          : DateTime.now(),
      synced: true,
    );
  }
}
