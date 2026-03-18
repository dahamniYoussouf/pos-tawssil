import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'print_service.dart';
import 'print_log_service.dart';

class SyncService {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();

  bool _isSyncing = false;
  bool _isOnline = false;
  bool _pendingSync = false;
  StreamController<SyncStatus> _statusController = StreamController.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  bool get isOnline => _isOnline;

  String _buildFallbackCategoryName(String categoryId) {
    if (categoryId.length > 8) {
      return 'Categorie ${categoryId.substring(0, 8)}...';
    }
    return 'Categorie';
  }

  SyncService() {
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        syncAll();
      } else {
        _updateStatus(SyncStatus(
          isSyncing: false,
          message: 'Hors ligne - les actions seront synchronisAes plus tard',
          success: false,
        ));
      }
    });
  }

  // ========== SYNC MENU FROM API TO LOCAL ==========

  Future<void> syncMenuFromApi() async {
    if (_isSyncing) return;
    if (!_isOnline) {
      _pendingSync = true;
      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Hors ligne - synchronisation menu en attente',
        success: false,
      ));
      return;
    }

    try {
      _isSyncing = true;
      _updateStatus(SyncStatus(
        isSyncing: true,
        message: 'Synchronisation du menu...',
      ));

      final restaurantId = await _api.getRestaurantId();
      if (restaurantId == null || restaurantId.isEmpty) {
        throw Exception(
            'Restaurant ID introuvable pour la synchronisation POS');
      }

      List<FoodCategory> categories = const [];

      // Sync categories first
      try {
        categories = await _api.fetchFoodCategories();
      } catch (e) {
        print('⚠️ Failed to sync categories: $e');
      }

      // Then sync menu items
      final menuItems = await _api.fetchMenuItems();
      final knownCategoryIds =
          categories.map((category) => category.id).toSet();

      // Replace the local catalog with the current restaurant catalog so POS
      // never keeps menu data from another restaurant.
      await _db.clearMenuCatalog();

      for (var category in categories) {
        await _db.insertFoodCategory({
          'id': category.id,
          'restaurant_id': category.restaurantId,
          'nom': category.nom,
          'description': category.description,
          'icone_url': category.iconeUrl,
          'ordre_affichage': category.ordreAffichage,
          'created_at': category.createdAt.toIso8601String(),
          'updated_at': category.updatedAt.toIso8601String(),
        });
      }

      final missingCategoryIds = menuItems
          .map((item) => item.categoryId)
          .where((categoryId) =>
              categoryId.isNotEmpty && !knownCategoryIds.contains(categoryId))
          .toSet();

      for (final categoryId in missingCategoryIds) {
        final now = DateTime.now().toIso8601String();
        await _db.insertFoodCategory({
          'id': categoryId,
          'restaurant_id': restaurantId,
          'nom': _buildFallbackCategoryName(categoryId),
          'description': null,
          'icone_url': null,
          'ordre_affichage': null,
          'created_at': now,
          'updated_at': now,
        });
      }

      for (var item in menuItems) {
        await _db.insertMenuItem(item.copyWith(synced: true));
      }

      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Menu synchronisé: ${menuItems.length} items',
        success: true,
      ));
    } catch (e) {
      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Erreur de synchronisation: ${e.toString()}',
        success: false,
      ));
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  // ========== SYNC LOCAL ORDERS TO API ==========

  Future<void> syncOrdersToApi() async {
    if (_isSyncing) return;
    if (!_isOnline) {
      _pendingSync = true;
      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Hors ligne - synchronisation des commandes en attente',
        success: false,
      ));
      return;
    }

    try {
      _isSyncing = true;
      final unsyncedOrders = await _db.getUnsyncedOrders();

      if (unsyncedOrders.isEmpty) {
        _updateStatus(SyncStatus(
          isSyncing: false,
          message: 'Aucune commande à synchroniser',
          success: true,
        ));
        return;
      }

      _updateStatus(SyncStatus(
        isSyncing: true,
        message: 'Synchronisation de ${unsyncedOrders.length} commandes...',
      ));

      int successCount = 0;
      for (var order in unsyncedOrders) {
        try {
          await _api.createOrder(order);
          await _db.markOrderAsSynced(order.id);
          successCount++;
        } catch (e) {
          print('Failed to sync order ${order.id}: $e');
        }
      }

      _updateStatus(SyncStatus(
        isSyncing: false,
        message:
            '$successCount/${unsyncedOrders.length} commandes synchronisées',
        success: true,
      ));
    } catch (e) {
      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Erreur: ${e.toString()}',
        success: false,
      ));
    } finally {
      _isSyncing = false;
    }
  }

  // ========== SYNC ALL ==========

  Future<void> syncAll() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _isOnline = false;
      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Pas de connexion Internet',
        success: false,
      ));
      return;
    }
    _isOnline = true;
    _pendingSync = false;

    await syncMenuFromApi();
    await syncOrdersToApi();
    await syncPrintLogs(); // Synchroniser les logs d'impression
  }

  /// Synchronise les logs d'impression vers l'API
  Future<void> syncPrintLogs() async {
    if (_isSyncing) return;
    if (!_isOnline) {
      _pendingSync = true;
      return;
    }

    try {
      final printLogService = PrintLogService();
      final unsyncedLogs = await printLogService.getUnsyncedLogs();

      if (unsyncedLogs.isEmpty) {
        return;
      }

      print('📤 Syncing ${unsyncedLogs.length} print log(s)...');

      int successCount = 0;
      for (final log in unsyncedLogs) {
        try {
          // Envoyer le log au backend (vous pouvez créer un endpoint pour ça)
          // Pour l'instant, on marque juste comme synchronisé
          // TODO: Créer endpoint backend pour recevoir les logs
          await printLogService.markAsSynced(log['id']);
          successCount++;
        } catch (e) {
          print('⚠️ Failed to sync print log ${log['id']}: $e');
        }
      }

      print('✅ $successCount/${unsyncedLogs.length} print logs synced');
    } catch (e) {
      print('⚠️ Error syncing print logs: $e');
    }
  }

  // ========== SYNC QUEUE PROCESSING ==========

  Future<void> processSyncQueue() async {
    if (_isSyncing) return;
    if (!_isOnline) {
      _pendingSync = true;
      _updateStatus(SyncStatus(
        isSyncing: false,
        message: 'Hors ligne - file de synchronisation en attente',
        success: false,
      ));
      return;
    }

    try {
      final queue = await _db.getSyncQueue();

      for (var item in queue) {
        try {
          // Process sync queue item if needed
          // final data = jsonDecode(item['data']);

          await _db.removeSyncQueueItem(item['id']);
        } catch (e) {
          print('Failed to process sync queue item: $e');
        }
      }
    } catch (e) {
      print('Error processing sync queue: $e');
    }
  }

  void _updateStatus(SyncStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  SyncStatus currentStatus() {
    return SyncStatus(
      isSyncing: _isSyncing,
      message: _pendingSync && !_isOnline
          ? 'Hors ligne - synchronisation en attente'
          : (_isOnline ? 'ConnectA' : 'Hors ligne'),
      success: _isOnline && !_pendingSync,
    );
  }

  void dispose() {
    _statusController.close();
  }
}

class SyncStatus {
  final bool isSyncing;
  final String message;
  final bool success;

  SyncStatus({
    required this.isSyncing,
    required this.message,
    this.success = false,
  });
}
