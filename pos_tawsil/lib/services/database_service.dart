import 'package:sqflite/sqflite.dart';
import '../config/database_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/addition.dart';
import '../models/option_group.dart';
import 'dart:convert';


class DatabaseService {
  // ========== MENU ITEMS ==========
  
  Future<List<MenuItem>> getMenuItems() async {
    final db = await DatabaseConfig.database;
    final List<Map<String, dynamic>> maps = await db.query('menu_items');
    return Future.wait(maps.map((map) async {
      final additions = await _getAdditionsForMenuItem(map['id']);
      final optionGroups = await _getOptionGroupsForMenuItem(map['id'], additions);
      return MenuItem.fromMap(map).copyWith(additions: additions, optionGroups: optionGroups);
    }));
  }

  Future<List<MenuItem>> getMenuItemsForRestaurant(String? restaurantId) async {
    if (restaurantId == null || restaurantId.isEmpty) {
      return getMenuItems();
    }
    final db = await DatabaseConfig.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*
      FROM menu_items m
      INNER JOIN food_categories c ON c.id = m.category_id
      WHERE c.restaurant_id = ?
      ''',
      [restaurantId],
    );
    return Future.wait(maps.map((map) async {
      final additions = await _getAdditionsForMenuItem(map['id']);
      final optionGroups = await _getOptionGroupsForMenuItem(map['id'], additions);
      return MenuItem.fromMap(map).copyWith(additions: additions, optionGroups: optionGroups);
    }));
  }

  /// Récupère un menu item par son ID
  Future<MenuItem?> getMenuItemById(String id) async {
    final db = await DatabaseConfig.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    final additions = await _getAdditionsForMenuItem(map['id']);
    final optionGroups = await _getOptionGroupsForMenuItem(map['id'], additions);
    
    return MenuItem.fromMap(map).copyWith(
      additions: additions,
      optionGroups: optionGroups,
    );
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
      final optionGroups = await _getOptionGroupsForMenuItem(map['id'], additions);
      return MenuItem.fromMap(map).copyWith(additions: additions, optionGroups: optionGroups);
    }));
  }

  Future<void> insertMenuItem(MenuItem item) async {
    final db = await DatabaseConfig.database;
    await db.insert(
      'menu_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Store option groups
    await db.delete(
      'option_groups',
      where: 'menu_item_id = ?',
      whereArgs: [item.id],
    );

    await db.delete(
      'additions',
      where: 'menu_item_id = ?',
      whereArgs: [item.id],
    );

    final groupedAdditionIds = <String>{};
    for (final group in item.optionGroups) {
      final groupMap = group.toMap();
      groupMap['menu_item_id'] = item.id;
      await db.insert(
        'option_groups',
        groupMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final addition in group.additions) {
        final additionMap = addition.toMap();
        additionMap['menu_item_id'] = item.id;
        additionMap['option_group_id'] = group.id;
        await db.insert(
          'additions',
          additionMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        groupedAdditionIds.add(addition.id);
      }
    }

    for (final addition in item.additions.where((a) => !groupedAdditionIds.contains(a.id))) {
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
      'option_groups',
      where: 'menu_item_id = ?',
      whereArgs: [item.id],
    );

    await db.delete(
      'additions',
      where: 'menu_item_id = ?',
      whereArgs: [item.id],
    );
    final groupedAdditionIds = <String>{};
    for (final group in item.optionGroups) {
      final groupMap = group.toMap();
      groupMap['menu_item_id'] = item.id;
      await db.insert(
        'option_groups',
        groupMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final addition in group.additions) {
        final additionMap = addition.toMap();
        additionMap['menu_item_id'] = item.id;
        additionMap['option_group_id'] = group.id;
        await db.insert(
          'additions',
          additionMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        groupedAdditionIds.add(addition.id);
      }
    }

    for (final addition in item.additions.where((a) => !groupedAdditionIds.contains(a.id))) {
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
      'option_groups',
      where: 'menu_item_id = ?',
      whereArgs: [id],
    );
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

  Future<List<OptionGroup>> _getOptionGroupsForMenuItem(
    String menuItemId,
    List<Addition> additions,
  ) async {
    final db = await DatabaseConfig.database;
    final groupRows = await db.query(
      'option_groups',
      where: 'menu_item_id = ?',
      whereArgs: [menuItemId],
      orderBy: 'ordre_affichage ASC, created_at DESC',
    );

    final additionsByGroup = <String, List<Addition>>{};
    for (final addition in additions) {
      final groupId = addition.optionGroupId;
      if (groupId == null || groupId.isEmpty) continue;
      additionsByGroup.putIfAbsent(groupId, () => []).add(addition);
    }

    return groupRows.map((row) {
      final id = row['id'] as String? ?? '';
      return OptionGroup.fromMap(row).copyWith(
        additions: additionsByGroup[id] ?? const [],
      );
    }).toList();
  }

  // ========== FOOD CATEGORIES ==========
  
  Future<List<Map<String, dynamic>>> getFoodCategories({String? restaurantId}) async {
    final db = await DatabaseConfig.database;
    if (restaurantId != null && restaurantId.isNotEmpty) {
      return await db.query(
        'food_categories',
        where: 'restaurant_id = ?',
        whereArgs: [restaurantId],
        orderBy: 'ordre_affichage ASC, nom ASC',
      );
    }
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

  Future<void> clearMenuCacheForOtherRestaurants(String restaurantId) async {
    if (restaurantId.isEmpty) return;
    final db = await DatabaseConfig.database;
    await db.transaction((txn) async {
      await txn.delete(
        'food_categories',
        where: 'restaurant_id != ?',
        whereArgs: [restaurantId],
      );
      await txn.execute(
        'DELETE FROM menu_items WHERE category_id NOT IN (SELECT id FROM food_categories)',
      );
      await txn.execute(
        'DELETE FROM additions WHERE menu_item_id NOT IN (SELECT id FROM menu_items)',
      );
      await txn.execute(
        'DELETE FROM option_groups WHERE menu_item_id NOT IN (SELECT id FROM menu_items)',
      );
    });
  }

  Future<void> clearMenuCacheForRestaurant(String restaurantId) async {
    if (restaurantId.isEmpty) return;
    final db = await DatabaseConfig.database;
    await db.transaction((txn) async {
      await txn.delete(
        'food_categories',
        where: 'restaurant_id = ?',
        whereArgs: [restaurantId],
      );
      await txn.execute(
        'DELETE FROM menu_items WHERE category_id NOT IN (SELECT id FROM food_categories)',
      );
      await txn.execute(
        'DELETE FROM additions WHERE menu_item_id NOT IN (SELECT id FROM menu_items)',
      );
      await txn.execute(
        'DELETE FROM option_groups WHERE menu_item_id NOT IN (SELECT id FROM menu_items)',
      );
    });
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

  /// Met à jour l'ID/numéro d'une commande locale après sync serveur,
  /// puis marque la commande comme synchronisée.
  Future<void> markOrderAsSyncedWithServer({
    required String localOrderId,
    required String serverOrderId,
    required String serverOrderNumber,
  }) async {
    final db = await DatabaseConfig.database;
    await db.transaction((txn) async {
      // Réassigner les items/logs vers l'ID serveur si besoin
      if (serverOrderId != localOrderId) {
        await txn.update(
          'order_items',
          {'order_id': serverOrderId},
          where: 'order_id = ?',
          whereArgs: [localOrderId],
        );
        try {
          await txn.update(
            'print_logs',
            {
              'order_id': serverOrderId,
              'order_number': serverOrderNumber,
            },
            where: 'order_id = ?',
            whereArgs: [localOrderId],
          );
        } catch (_) {
          // print_logs peut ne pas exister selon la version du DB
        }
      }

      final existing = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [serverOrderId],
        limit: 1,
      );

      if (existing.isEmpty) {
        await txn.update(
          'orders',
          {
            'id': serverOrderId,
            'order_number': serverOrderNumber,
            'synced': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [localOrderId],
        );
      } else {
        await txn.update(
          'orders',
          {
            'order_number': serverOrderNumber,
            'synced': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [serverOrderId],
        );
        // Supprimer l'entrée locale si un doublon existe déjà
        await txn.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [localOrderId],
        );
      }
    });
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
  
  // Total des ventes (toutes) et ventes synchronisées
  final revenueAllResult = await db.rawQuery(
    'SELECT SUM(total_amount) as total FROM orders'
  );
  final revenueSyncedResult = await db.rawQuery(
    'SELECT SUM(total_amount) as total FROM orders WHERE synced = 1'
  );
  final totalRevenueAll = (revenueAllResult.first['total'] as num?)?.toDouble() ?? 0.0;
  final totalRevenueSynced = (revenueSyncedResult.first['total'] as num?)?.toDouble() ?? 0.0;
  
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
    'total_revenue': totalRevenueSynced,
    'total_revenue_all': totalRevenueAll,
    'today_orders': todayOrders,
    'unsynced_orders': unsyncedOrders,
  };
}
}
