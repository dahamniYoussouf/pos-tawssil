import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../config/database_config.dart';
import '../models/restaurant_printer.dart';

/// Service pour gérer les logs d'impression en mode offline
class PrintLogService {
  static const String _tableName = 'print_logs';
  final Uuid _uuid = const Uuid();

  /// Enregistre une demande d'impression (avant d'imprimer) pour éviter les doublons en cas de double clic / race.
  Future<void> logPrintRequested(String orderId, String orderNumber) async {
    try {
      final db = await DatabaseConfig.database;
      final logId = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      await db.insert(_tableName, {
        'id': logId,
        'order_id': orderId,
        'order_number': orderNumber,
        'printer_id': null,
        'printer_name': null,
        'printer_ip': null,
        'device_key': null,
        'status': 'requested',
        'success': 0,
        'error_message': null,
        'printed_at': now,
        'synced': 0,
      });
      print('📝 Print requested logged: $orderNumber');
    } catch (e) {
      print('❌ Error logging print requested: $e');
    }
  }

  /// Enregistre un log d'impression localement
  Future<void> logPrint({
    required String orderId,
    String? orderNumber,
    RestaurantPrinter? printer,
    String? deviceKey,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      final db = await DatabaseConfig.database;
      final logId = _uuid.v4();
      final printerIp = printer != null ? '${printer.ip}:${printer.port}' : null;
      await db.insert(_tableName, {
        'id': logId,
        'order_id': orderId,
        'order_number': orderNumber,
        'printer_id': printer?.id,
        'printer_name': printer?.name,
        'printer_ip': printerIp,
        'device_key': deviceKey,
        'status': success ? 'completed' : 'failed',
        'success': success ? 1 : 0,
        'error_message': errorMessage,
        'printed_at': DateTime.now().toIso8601String(),
        'synced': 0,
      });
      print('📝 Print log saved locally: $logId (${success ? "success" : "failed"})');
    } catch (e) {
      print('❌ Error saving print log: $e');
    }
  }

  /// Récupère tous les logs non synchronisés
  Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    try {
      final db = await DatabaseConfig.database;
      final logs = await db.query(
        _tableName,
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'printed_at ASC',
      );
      return logs;
    } catch (e) {
      print('❌ Error fetching unsynced print logs: $e');
      return [];
    }
  }

  /// Marque un log comme synchronisé
  Future<void> markAsSynced(String logId) async {
    try {
      final db = await DatabaseConfig.database;
      await db.update(
        _tableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [logId],
      );
    } catch (e) {
      print('❌ Error marking print log as synced: $e');
    }
  }

  /// Vérifie si une commande a déjà été imprimée avec succès
  Future<bool> hasOrderBeenPrinted(String orderId) async {
    try {
      final db = await DatabaseConfig.database;
      final logs = await db.query(
        _tableName,
        where: 'order_id = ? AND success = ?',
        whereArgs: [orderId, 1],
        limit: 1,
      );
      return logs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if order was printed: $e');
      return false;
    }
  }

  /// Vérifie si une commande a été imprimée récemment (dans les dernières minutes)
  Future<bool> hasOrderBeenPrintedRecently(String orderId, {int minutesThreshold = 2}) async {
    try {
      final db = await DatabaseConfig.database;
      final threshold = DateTime.now().subtract(Duration(minutes: minutesThreshold));
      final logs = await db.query(
        _tableName,
        where: 'order_id = ? AND success = ? AND printed_at >= ?',
        whereArgs: [orderId, 1, threshold.toIso8601String()],
        limit: 1,
      );
      return logs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking recent print: $e');
      return false;
    }
  }

  /// Vérifie si une commande est en cours d'impression ou déjà imprimée récemment (order_id ou order_number).
  /// Utilisé pour éviter doublons (double clic, job API + impression locale).
  Future<bool> hasOrderPrintInProgressOrDoneRecently(
    String orderId, {
    String? orderNumber,
    int minutesThreshold = 2,
  }) async {
    try {
      final db = await DatabaseConfig.database;
      final threshold = DateTime.now().subtract(Duration(minutes: minutesThreshold));
      final List<Map<String, dynamic>> logs;
      if (orderNumber != null && orderNumber.isNotEmpty) {
        logs = await db.query(
          _tableName,
          where: '(order_id = ? OR order_number = ?) AND printed_at >= ?',
          whereArgs: [orderId, orderNumber, threshold.toIso8601String()],
          limit: 1,
        );
      } else {
        logs = await db.query(
          _tableName,
          where: 'order_id = ? AND printed_at >= ?',
          whereArgs: [orderId, threshold.toIso8601String()],
          limit: 1,
        );
      }
      return logs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking print in progress/done: $e');
      return false;
    }
  }

  /// Vérifie si cette commande a déjà été imprimée sur ce périphérique (même imprimante configurée plusieurs fois).
  Future<bool> hasOrderBeenPrintedToDeviceRecently(
    String orderId,
    String? orderNumber,
    String deviceKey, {
    int minutesThreshold = 2,
  }) async {
    if (deviceKey.isEmpty) return false;
    try {
      final db = await DatabaseConfig.database;
      final threshold = DateTime.now().subtract(Duration(minutes: minutesThreshold));
      final List<Map<String, dynamic>> logs;
      if (orderNumber != null && orderNumber.isNotEmpty) {
        logs = await db.query(
          _tableName,
          where: 'success = ? AND device_key = ? AND printed_at >= ? AND (order_id = ? OR order_number = ?)',
          whereArgs: [1, deviceKey, threshold.toIso8601String(), orderId, orderNumber],
          limit: 1,
        );
      } else {
        logs = await db.query(
          _tableName,
          where: 'success = ? AND device_key = ? AND order_id = ? AND printed_at >= ?',
          whereArgs: [1, deviceKey, orderId, threshold.toIso8601String()],
          limit: 1,
        );
      }
      return logs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking print to device: $e');
      return false;
    }
  }

  /// Supprime les logs synchronisés (optionnel, pour nettoyer)
  Future<void> deleteSyncedLogs({int olderThanDays = 7}) async {
    try {
      final db = await DatabaseConfig.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      
      await db.delete(
        _tableName,
        where: 'synced = ? AND printed_at < ?',
        whereArgs: [1, cutoffDate.toIso8601String()],
      );
      
      print('🗑️ Deleted old synced print logs');
    } catch (e) {
      print('❌ Error deleting old print logs: $e');
    }
  }
}
