import 'package:restaurant_app/src/core/utils/parsers.dart' as parsers;

class MenuItemModel {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final int? preparationTime;
  final String? ingredients;
  final String? allergens;
  final String? photoUrl;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? restaurantId;

  MenuItemModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.preparationTime,
    this.ingredients,
    this.allergens,
    this.photoUrl,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
    this.restaurantId,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MenuItemModel(id: '', name: '', price: 0.0);
    }

    return MenuItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      categoryId: json['category_id']?.toString(),
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description'],
      price: parsers.parseDouble(json['prix'] ?? json['price']),
      preparationTime: parsers.parseNullableInt(json['temps_preparation'] ??
          json['preparation_time'] ??
          json['preparationTimeMinutes']),
      ingredients: json['ingredients']?.toString(),
      allergens:
          json['allergenes']?.toString() ?? json['allergens']?.toString(),
      photoUrl: json['photo_url'] ??
          json['photoUrl'] ??
          json['image'] ??
          json['image_url'],
      isAvailable: json['is_available'] ??
          json['isAvailable'] ??
          json['disponible'] ??
          true,
      createdAt: parsers.parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parsers.parseDate(json['updated_at'] ?? json['updatedAt']),
      restaurantId: json['restaurant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'nom': name,
      'description': description,
      'prix': price,
      'temps_preparation': preparationTime,
      'ingredients': ingredients,
      'allergenes': allergens,
      'photo_url': photoUrl,
      'is_available': isAvailable,
      'disponible': isAvailable,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'category_id': categoryId,
      'nom': name,
      'description': description,
      'prix': price,
      'temps_preparation': preparationTime,
      'ingredients': ingredients,
      'allergenes': allergens,
      'photo_url': photoUrl,
      'disponible': isAvailable,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'category_id': categoryId,
      'nom': name,
      'description': description,
      'prix': price,
      'temps_preparation': preparationTime,
      'ingredients': ingredients,
      'allergenes': allergens,
      'photo_url': photoUrl,
      'is_available': isAvailable,
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    int? preparationTime,
    String? ingredients,
    String? allergens,
    String? photoUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? restaurantId,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      preparationTime: preparationTime ?? this.preparationTime,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      photoUrl: photoUrl ?? this.photoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }
}
