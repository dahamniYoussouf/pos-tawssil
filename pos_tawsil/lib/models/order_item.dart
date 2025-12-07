import 'dart:convert';
import 'order_item_addition.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String menuItemName;
  final String? photoUrl;
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
    this.photoUrl,
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
      'photo_url': photoUrl,
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
      photoUrl: map['photo_url'],
      quantite: _toInt(map['quantite']),
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
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      photoUrl: photoUrl ?? this.photoUrl,
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
    final rawAdditions = (json['additions'] ??
        json['order_item_additions'] ??
        json['item_additions']) as List<dynamic>? ?? [];
    final additions = rawAdditions
        .map((a) => OrderItemAddition.fromJson(a))
        .toList();
    final additionsTotalFromList = additions.fold<double>(0, (sum, a) => sum + a.total);
    final quantiteParsed = _toInt(json['quantity'] ?? json['quantite'] ?? json['qty']);
    final prixUnitaireParsed = _toDouble(json['unit_price'] ?? json['prix_unitaire'] ?? json['prix'] ?? json['price']);
    final prixTotalParsed = _toDouble(json['total_price'] ?? json['prix_total']);
    final totalWithFallback = prixTotalParsed != 0
        ? prixTotalParsed
        : (prixUnitaireParsed * quantiteParsed) + additionsTotalFromList;
    final menuItemData = json['menu_item'] as Map<String, dynamic>?;
    final parsedName = json['menu_item_name'] ??
        json['nom'] ??
        json['name'] ??
        json['title'] ??
        menuItemData?['nom'] ??
        menuItemData?['name'] ??
        menuItemData?['title'] ??
        '';
    final parsedPhoto = json['photo_url'] ??
        json['image_url'] ??
        json['image'] ??
        json['photo'] ??
        menuItemData?['photo_url'] ??
        menuItemData?['image_url'] ??
        menuItemData?['image'] ??
        menuItemData?['photo'];

    return OrderItem(
      id: json['id'] ?? json['order_item_id'] ?? '',
      orderId: json['order_id'] ?? '',
      menuItemId: json['menu_item_id'] ?? json['item_id'] ?? '',
      menuItemName: parsedName,
      photoUrl: parsedPhoto,
      quantite: quantiteParsed,
      prixUnitaire: prixUnitaireParsed,
      prixTotal: totalWithFallback,
      additionsTotal: _toDouble(json['additions_total']) ?? additionsTotalFromList,
      additions: additions,
      instructionsSpeciales: json['special_instructions'] ?? json['instructions'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
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

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }
}
