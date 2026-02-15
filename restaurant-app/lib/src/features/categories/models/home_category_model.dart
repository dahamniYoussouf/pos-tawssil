class HomeCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int displayOrder;
  final int restaurantsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HomeCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.displayOrder,
    required this.restaurantsCount,
    this.createdAt,
    this.updatedAt,
  });

  factory HomeCategoryModel.fromJson(Map<String, dynamic> json) {
    return HomeCategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] ?? json['imageUrl'] as String?,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? json['displayOrder'] ?? 0) as int,
      restaurantsCount:
          (json['restaurants_count'] ?? json['restaurantsCount'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': isActive,
      'display_order': displayOrder,
      'restaurants_count': restaurantsCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
