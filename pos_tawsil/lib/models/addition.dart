class Addition {
  final String id;
  final String menuItemId;
  final String nom;
  final String? description;
  final double prix;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Addition({
    required this.id,
    required this.menuItemId,
    required this.nom,
    this.description,
    required this.prix,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Addition.fromJson(Map<String, dynamic> json) {
    return Addition(
      id: json['id'] ?? '',
      menuItemId: json['menu_item_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      prix: _parseDouble(json['prix']),
      isAvailable: json['is_available'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  factory Addition.fromMap(Map<String, dynamic> map) {
    return Addition(
      id: map['id'] ?? '',
      menuItemId: map['menu_item_id'] ?? '',
      nom: map['nom'] ?? '',
      description: map['description'],
      prix: _parseDouble(map['prix']),
      isAvailable: map['is_available'] == 1 || map['is_available'] == true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'nom': nom,
      'description': description,
      'prix': prix,
      'is_available': isAvailable ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
