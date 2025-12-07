import 'dart:convert';
import 'order_item_addition.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String menuItemName;
  final int quantite;
  final double prixUnitaire;
  final double prixTotal;
  final double additionsTotal;
  final List<OrderItemAddition> additions;
  final String? instructionsSpeciales;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixTotal,
    this.additionsTotal = 0,
    this.additions = const [],
    this.instructionsSpeciales,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'menu_item_name': menuItemName,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'prix_total': prixTotal,
      'additions_total': additionsTotal,
      'additions_json': jsonEncode(additions.map((a) => a.toJson()).toList()),
      'instructions_speciales': instructionsSpeciales,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final decodedAdditions = _decodeAdditions(map['additions_json']);
    final additionsTotalFromList = decodedAdditions.fold<double>(0, (sum, a) => sum + a.total);
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      menuItemId: map['menu_item_id'],
      menuItemName: map['menu_item_name'],
      quantite: map['quantite'],
      prixUnitaire: (map['prix_unitaire'] as num).toDouble(),
      prixTotal: (map['prix_total'] as num).toDouble(),
      additionsTotal: (map['additions_total'] as num?)?.toDouble() ?? additionsTotalFromList,
      additions: decodedAdditions,
      instructionsSpeciales: map['instructions_speciales'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? menuItemId,
    String? menuItemName,
    int? quantite,
    double? prixUnitaire,
    double? prixTotal,
    double? additionsTotal,
    List<OrderItemAddition>? additions,
    String? instructionsSpeciales,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prixTotal: prixTotal ?? this.prixTotal,
      additionsTotal: additionsTotal ?? this.additionsTotal,
      additions: additions ?? this.additions,
      instructionsSpeciales: instructionsSpeciales ?? this.instructionsSpeciales,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final additions = (json['additions'] as List<dynamic>?)
            ?.map((a) => OrderItemAddition.fromJson(a))
            .toList() ??
        const [];
    final additionsTotalFromList = additions.fold<double>(0, (sum, a) => sum + a.total);
  return OrderItem(
    id: json['id'],
    orderId: json['order_id'],
    menuItemId: json['menu_item_id'],
    menuItemName: json['menu_item_name'] ?? '', // fallback if API doesn't send name
    quantite: json['quantity'],
    prixUnitaire: _toDouble(json['unit_price']),
    prixTotal: _toDouble(json['total_price']),
    additionsTotal: _toDouble(json['additions_total']) ?? additionsTotalFromList,
    additions: additions,
    instructionsSpeciales: json['special_instructions'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}

  static List<OrderItemAddition> _decodeAdditions(dynamic jsonStr) {
    if (jsonStr == null) return const [];
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is List) {
        return decoded.map((a) => OrderItemAddition.fromJson(a)).toList();
      }
    } catch (_) {}
    return const [];
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
