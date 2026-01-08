class MenuModel {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String nom;
  final String? description;
  final double prix;
  final double? displayPrice;
  final bool isOnPromotion;
  final String? promotionHighlight;
  final int? tempsPreparation;
  final String? ingredients;
  final String? allergenes;
  final String? photoUrl;
  final bool disponible;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MenuItemCategory? category;
  final List<MenuItemAddition> additions;
  final int additionsCount;
  final List<dynamic> promotions;
  final bool isFavorite;
  final String? favoriteId;
  final double? rating;
  final String categoryName;

  MenuModel({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.nom,
    this.description,
    required this.prix,
    this.displayPrice,
    this.isOnPromotion = false,
    this.promotionHighlight,
    this.tempsPreparation,
    this.ingredients,
    this.allergenes,
    this.photoUrl,
    required this.disponible,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.additions = const [],
    this.additionsCount = 0,
    this.promotions = const [],
    this.isFavorite = false,
    this.favoriteId,
    this.rating,
    required this.categoryName,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json, String categoryName) {
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

    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final additionsList = json['additions'] as List<dynamic>?;
    final additions = additionsList != null
        ? additionsList
            .map((item) =>
                MenuItemAddition.fromJson(item as Map<String, dynamic>))
            .toList()
        : <MenuItemAddition>[];

    final prixValue = parsePrice(
      json['prix'] ??
          json['price'] ??
          json['prix_value'] ??
          json['display_price'] ??
          json['promo_price'],
    );
    final displayPriceValue = json['promo_price'] != null
        ? parsePrice(json['promo_price'])
        : (json['display_price'] != null
            ? parsePrice(json['display_price'])
            : null);

    final additionsCountValue =
        json['additions_count'] as int? ?? additions.length;

    final promotionsList = json['promotions'] as List<dynamic>? ?? [];

    return MenuModel(
      id: (json['id'] ?? json['_id']).toString(),
      restaurantId: restaurantIdVal?.toString() ?? '',
      categoryId: categoryIdVal?.toString() ?? '',
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      description:
          (json['description'] as String?) ?? (json['desc'] as String?),
      prix: prixValue,
      displayPrice: displayPriceValue,
      isOnPromotion:
          (json['is_on_promotion'] ?? json['isOnPromotion']) as bool? ?? false,
      promotionHighlight: (json['promotion_highlight'] ??
          json['promotionHighlight']) as String?,
      tempsPreparation: (json['temps_preparation'] ??
          json['tempsPreparation'] ??
          json['preparation_time']) as int?,
      ingredients: json['ingredients'] as String?,
      allergenes: json['allergenes'] as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl'] ?? json['imageUrl'])
          as String?,
      disponible: (json['is_available'] ?? json['disponible']) as bool? ?? true,
      createdAt: parseDateTime(created),
      updatedAt: parseDateTime(updated),
      category: _asMap(json['category']) != null
          ? MenuItemCategory.fromJson(_asMap(json['category'])!)
          : null,
      additions: additions,
      additionsCount: additionsCountValue,
      promotions: promotionsList,
      isFavorite: (json['is_favorite'] ?? json['isFavorite']) as bool? ?? false,
      favoriteId: (json['favorite_id'] ?? json['favoriteId']) as String?,
      rating: _parseRating(json['rating'] ??
          json['avg_rating'] ??
          json['average_rating'] ??
          json['note']),
      categoryName: categoryName,
    );
  }

  static double parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  static double? _parseRating(dynamic rating) {
    if (rating == null) return null;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) {
      final parsed = double.tryParse(rating);
      return parsed;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'category_id': categoryId,
      'nom': nom,
      'description': description,
      'prix': prix,
      if (displayPrice != null) 'display_price': displayPrice,
      'is_on_promotion': isOnPromotion,
      if (promotionHighlight != null) 'promotion_highlight': promotionHighlight,
      'temps_preparation': tempsPreparation,
      'ingredients': ingredients,
      'allergenes': allergenes,
      'photo_url': photoUrl,
      'disponible': disponible,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (category != null) 'category': category!.toJson(),
      'additions': additions.map((addition) => addition.toJson()).toList(),
      'additions_count': additionsCount,
      'promotions': promotions,
      'is_favorite': isFavorite,
      if (favoriteId != null) 'favorite_id': favoriteId,
      if (rating != null) 'rating': rating,
    };
  }

  String get imageUrl => photoUrl ?? 'https://via.placeholder.com/150';

  String get priceFormatted => '${prix.toStringAsFixed(0)} DA';

  String get displayPriceFormatted => displayPrice != null
      ? '${displayPrice!.toStringAsFixed(0)} DA'
      : priceFormatted;

  double get effectivePrice => displayPrice ?? prix;

  String get ratingFormatted =>
      rating != null ? rating!.toStringAsFixed(1) : '0.0';
}

class MenuItemCategory {
  final String id;
  final String nom;
  final String? description;
  final String? iconeUrl;
  final int ordreAffichage;

  MenuItemCategory({
    required this.id,
    required this.nom,
    this.description,
    this.iconeUrl,
    this.ordreAffichage = 0,
  });

  factory MenuItemCategory.fromJson(Map<String, dynamic> json) {
    return MenuItemCategory(
      id: (json['id'] ?? json['_id']).toString(),
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      description: json['description'] as String?,
      iconeUrl: (json['icone_url'] ?? json['iconeUrl']) as String?,
      ordreAffichage:
          (json['ordre_affichage'] ?? json['ordreAffichage'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      if (iconeUrl != null) 'icone_url': iconeUrl,
      'ordre_affichage': ordreAffichage,
    };
  }
}

class MenuItemAddition {
  final String id;
  final String nom;
  final String? description;
  final double prix;
  final bool isAvailable;

  MenuItemAddition({
    required this.id,
    required this.nom,
    this.description,
    required this.prix,
    required this.isAvailable,
  });

  factory MenuItemAddition.fromJson(Map<String, dynamic> json) {
    return MenuItemAddition(
      id: (json['id'] ?? json['_id']).toString(),
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      description: json['description'] as String?,
      prix: MenuModel.parsePrice(json['prix'] ?? json['price']),
      isAvailable:
          (json['is_available'] ?? json['isAvailable']) as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      'prix': prix,
      'is_available': isAvailable,
    };
  }

  String get priceFormatted => '${prix.toStringAsFixed(0)} DA';
}
