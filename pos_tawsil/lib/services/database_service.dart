import 'package:sqflite/sqflite.dart';
import '../config/database_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/addition.dart';
import 'dart:convert';


class DatabaseService {
  // ========== MENU ITEMS ==========
  
  Future<List<MenuItem>> getMenuItems() async {
    final db = await DatabaseConfig.database;
    final List<Map<String, dynamic>> maps = await db.query('menu_items');
    return Future.wait(maps.map((map) async {
      final additions = await _getAdditionsForMenuItem(map['id']);
      return MenuItem.fromMap(map).copyWith(additions: additions);
    }));
  }

  Future<List<MenuItem>> getMenuItemsByCategory(String categoryId) async {
    final db = await DatabaseConfig.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return Future.wait(maps.map((map) async {
      final additions = await _getAdditionsForMenuItem(map['id']);
      return MenuItem.fromMap(map).copyWith(additions: additions);
    }));
  }

  Future<void> insertMenuItem(MenuItem item) async {
    final db = await DatabaseConfig.database;
    await db.insert(
      'menu_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Store additions
    await db.delete(
      'additions',
      where: 'menu_item_id = ?',
      whereArgs: [item.id],
    );

    for (final addition in item.additions) {
      final additionMap = addition.toMap();
      additionMap['menu_item_id'] = item.id; // ensure linkage even if API omits it
      await db.insert(
        'additions',
        additionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final db = await DatabaseConfig.database;
    await db.update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    await db.delete(
      'additions',
      where: 'menu_item_id = ?',
      whereArgs: [item.id],
    );
    for (final addition in item.additions) {
      final additionMap = addition.toMap();
      additionMap['menu_item_id'] = item.id; // ensure linkage even if missing in payload
      await db.insert(
        'additions',
        additionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteMenuItem(String id) async {
    final db = await DatabaseConfig.database;
    await db.delete(
      'additions',
      where: 'menu_item_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Addition>> _getAdditionsForMenuItem(String menuItemId) async {
    final db = await DatabaseConfig.database;
    final rows = await db.query(
      'additions',
      where: 'menu_item_id = ?',
      whereArgs: [menuItemId],
    );
    return rows.map((r) => Addition.fromMap(r)).toList();
  }

  // ========== FOOD CATEGORIES ==========
  
  Future<List<Map<String, dynamic>>> getFoodCategories() async {
    final db = await DatabaseConfig.database;
    return await db.query('food_categories', orderBy: 'ordre_affichage ASC, nom ASC');
  }

  Future<void> insertFoodCategory(Map<String, dynamic> category) async {
    final db = await DatabaseConfig.database;
    await db.insert(
      'food_categories',
      {
        'id': category['id'],
        'restaurant_id': category['restaurant_id'],
        'nom': category['nom'],
        'description': category['description'],
        'icone_url': category['icone_url'],
        'ordre_affichage': category['ordre_affichage'],
        'created_at': category['created_at'],
        'updated_at': category['updated_at'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCategoryName(String categoryId) async {
    final db = await DatabaseConfig.database;
    final result = await db.query(
      'food_categories',
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['nom'] as String?;
  }

  // ========== ORDERS ==========
  
  Future<void> insertOrder(Order order) async {
    final db = await DatabaseConfig.database;
    await db.transaction((txn) async {
      // Insert order
      await txn.insert(
        'orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Insert order items
      for (var item in order.items) {
      await txn.insert(
        'order_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

        // Store additions JSON for readability (already inside toMap)
      }
    });
  }

  Future<List<Order>> getUnsyncedOrders() async {
    final db = await DatabaseConfig.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    List<Order> orders = [];
    for (var map in maps) {
      // Get order items
      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );
      
      orders.add(Order.fromMap(map, items));
    }
    
    return orders;
  }

  Future<void> markOrderAsSynced(String orderId) async {
    final db = await DatabaseConfig.database;
    await db.update(
      'orders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ========== SYNC QUEUE ==========
  
  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final db = await DatabaseConfig.database;
    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await DatabaseConfig.database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: 10, // Process 10 at a time
    );
  }

  Future<void> removeSyncQueueItem(int id) async {
    final db = await DatabaseConfig.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  
Future<List<Order>> getAllOrders() async {
  final db = await DatabaseConfig.database;
  
  // Récupérer toutes les commandes
  final List<Map<String, dynamic>> orderMaps = await db.query(
    'orders',
    orderBy: 'created_at DESC',
  );
  
  List<Order> orders = [];
  
  for (var orderMap in orderMaps) {
    // Récupérer les items de chaque commande
    final items = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderMap['id']],
    );
    
    orders.add(Order.fromMap(orderMap, items));
  }
  
  return orders;
}

// ==================== GET ORDER BY ID ====================

Future<Order?> getOrderById(String orderId) async {
  final db = await DatabaseConfig.database;
  
  final List<Map<String, dynamic>> orderMaps = await db.query(
    'orders',
    where: 'id = ?',
    whereArgs: [orderId],
    limit: 1,
  );
  
  if (orderMaps.isEmpty) return null;
  
  final items = await db.query(
    'order_items',
    where: 'order_id = ?',
    whereArgs: [orderId],
  );
  
  return Order.fromMap(orderMaps.first, items);
}

// ==================== GET ORDERS BY DATE RANGE ====================

Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
  final db = await DatabaseConfig.database;
  
  final List<Map<String, dynamic>> orderMaps = await db.query(
    'orders',
    where: 'created_at >= ? AND created_at <= ?',
    whereArgs: [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ],
    orderBy: 'created_at DESC',
  );
  
  List<Order> orders = [];
  
  for (var orderMap in orderMaps) {
    final items = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderMap['id']],
    );
    
    orders.add(Order.fromMap(orderMap, items));
  }
  
  return orders;
}

// ==================== GET ORDERS BY STATUS ====================

Future<List<Order>> getOrdersByStatus(String status) async {
  final db = await DatabaseConfig.database;
  
  final List<Map<String, dynamic>> orderMaps = await db.query(
    'orders',
    where: 'status = ?',
    whereArgs: [status],
    orderBy: 'created_at DESC',
  );
  
  List<Order> orders = [];
  
  for (var orderMap in orderMaps) {
    final items = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderMap['id']],
    );
    
    orders.add(Order.fromMap(orderMap, items));
  }
  
  return orders;
}

// ==================== GET TODAY'S ORDERS ====================

Future<List<Order>> getTodayOrders() async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  
  return getOrdersByDateRange(startOfDay, endOfDay);
}

// ==================== GET ORDERS STATISTICS ====================

Future<Map<String, dynamic>> getOrdersStatistics() async {
  final db = await DatabaseConfig.database;
  
  // Total des commandes
  final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
  final totalOrders = totalResult.first['count'] as int;
  
  // Total des ventes
  final revenueResult = await db.rawQuery(
    'SELECT SUM(total_amount) as total FROM orders WHERE synced = 1'
  );
  final totalRevenue = (revenueResult.first['total'] as num?)?.toDouble() ?? 0.0;
  
  // Commandes du jour
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
  final todayResult = await db.rawQuery(
    'SELECT COUNT(*) as count FROM orders WHERE created_at >= ?',
    [startOfDay]
  );
  final todayOrders = todayResult.first['count'] as int;
  
  // Commandes non synchronisées
  final unsyncedResult = await db.rawQuery(
    'SELECT COUNT(*) as count FROM orders WHERE synced = 0'
  );
  final unsyncedOrders = unsyncedResult.first['count'] as int;
  
  return {
    'total_orders': totalOrders,
    'total_revenue': totalRevenue,
    'today_orders': todayOrders,
    'unsynced_orders': unsyncedOrders,
  };
}
}
