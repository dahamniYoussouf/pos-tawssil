class MenuItem {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String nom;
  final String? description;
  final double prix;
  final int? tempsPreparation;
  final String? ingredients;
  final String? allergenes;
  final String? photoUrl;
  final bool disponible;
  final DateTime createdAt;
  final DateTime updatedAt;

  final MenuItemCategory? category;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.nom,
    this.description,
    required this.prix,
    this.tempsPreparation,
    this.ingredients,
    this.allergenes,
    this.photoUrl,
    required this.disponible,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // helper to safely read nested maps
    Map<String, dynamic>? _asMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      return null;
    }

    final restaurantIdVal = json['restaurant_id'] ??
        json['restaurantId'] ??
        (json['restaurant'] is Map ? (json['restaurant']['id']) : null) ??
        '';
    final categoryIdVal = json['category_id'] ??
        json['categoryId'] ??
        (json['category'] is Map ? (json['category']['id']) : null) ??
        '';

    final created = json['created_at'] ??
        json['createdAt'] ??
        DateTime.now().toIso8601String();
    final updated = json['updated_at'] ??
        json['updatedAt'] ??
        DateTime.now().toIso8601String();

    return MenuItem(
      id: (json['id'] ?? json['_id']).toString(),
      restaurantId: restaurantIdVal?.toString() ?? '',
      categoryId: categoryIdVal?.toString() ?? '',
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      description:
          (json['description'] as String?) ?? (json['desc'] as String?),
      prix: _parsePrice(json['prix'] ?? json['price'] ?? json['prix_value']),
      tempsPreparation: (json['temps_preparation'] ??
          json['tempsPreparation'] ??
          json['preparation_time']) as int?,
      ingredients: json['ingredients'] as String?,
      allergenes: json['allergenes'] as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl'] ?? json['imageUrl'])
          as String?,
      disponible: (json['is_available'] ?? json['disponible']) as bool? ?? true,
      createdAt: DateTime.parse(created as String),
      updatedAt: DateTime.parse(updated as String),
      category: _asMap(json['category']) != null
          ? MenuItemCategory.fromJson(_asMap(json['category'])!)
          : null,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'category_id': categoryId,
      'nom': nom,
      'description': description,
      'prix': prix,
      'temps_preparation': tempsPreparation,
      'ingredients': ingredients,
      'allergenes': allergenes,
      'photo_url': photoUrl,
      'disponible': disponible,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (category != null) 'category': category!.toJson(),
    };
  }

  String get imageUrl => photoUrl ?? 'https://via.placeholder.com/150';

  String get priceFormatted => '${prix.toStringAsFixed(0)} DA';
}

class MenuItemCategory {
  final String id;
  final String nom;

  MenuItemCategory({
    required this.id,
    required this.nom,
  });

  factory MenuItemCategory.fromJson(Map<String, dynamic> json) {
    return MenuItemCategory(
      id: json['id'] as String,
      nom: json['nom'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
    };
  }
}
