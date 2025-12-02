import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class CategoryModel {
  final String id;
  final String nom;
  final String description;
  final String? iconeUrl;
  final int ordreAffichage;
  final List<MenuItem> items;
  final int itemsCount;

  CategoryModel({
    required this.id,
    required this.nom,
    required this.description,
    this.iconeUrl,
    required this.ordreAffichage,
    required this.items,
    required this.itemsCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((item) => MenuItem.fromJson(item as Map<String, dynamic>?))
        .toList();

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconeUrl: json['icone_url']?.toString() ?? json['iconeUrl']?.toString(),
      ordreAffichage: json['ordre_affichage'] ?? json['ordreAffichage'] ?? 0,
      items: items,
      itemsCount: json['items_count'] ?? json['itemsCount'] ?? items.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'icone_url': iconeUrl,
      'ordre_affichage': ordreAffichage,
      'items': items
          .map((item) => {
                'id': item.id,
                'category_id': item.categoryId,
                'nom': item.name,
                'description': item.description,
                'prix': item.price,
                'photo_url': item.photoUrl,
                'is_available': item.isAvailable,
                'temps_preparation': item.preparationTimeMinutes,
                'created_at': item.createdAt?.toIso8601String(),
                'updated_at': item.updatedAt?.toIso8601String(),
                'restaurant_id': item.restaurantId,
              })
          .toList(),
      'items_count': itemsCount,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? nom,
    String? description,
    String? iconeUrl,
    int? ordreAffichage,
    List<MenuItem>? items,
    int? itemsCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      iconeUrl: iconeUrl ?? this.iconeUrl,
      ordreAffichage: ordreAffichage ?? this.ordreAffichage,
      items: items ?? this.items,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }
}
