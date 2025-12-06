class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String menuItemName;
  final int quantite;
  final double prixUnitaire;
  final double prixTotal;
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
      'instructions_speciales': instructionsSpeciales,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      menuItemId: map['menu_item_id'],
      menuItemName: map['menu_item_name'],
      quantite: map['quantite'],
      prixUnitaire: (map['prix_unitaire'] as num).toDouble(),
      prixTotal: (map['prix_total'] as num).toDouble(),
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
      instructionsSpeciales: instructionsSpeciales ?? this.instructionsSpeciales,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  factory OrderItem.fromJson(Map<String, dynamic> json) {
  return OrderItem(
    id: json['id'],
    orderId: json['order_id'],
    menuItemId: json['menu_item_id'],
    menuItemName: json['menu_item_name'] ?? '', // fallback if API doesn't send name
    quantite: json['quantity'],
    prixUnitaire: (json['unit_price'] as num).toDouble(),
    prixTotal: (json['total_price'] as num).toDouble(),
    instructionsSpeciales: json['special_instructions'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}

}