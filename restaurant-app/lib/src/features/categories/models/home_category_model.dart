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
    bool parseBool(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return true;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    return HomeCategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      isActive: parseBool(json['is_active'] ?? json['isActive']),
      displayOrder: parseInt(json['display_order'] ?? json['displayOrder']),
      restaurantsCount:
          parseInt(json['restaurants_count'] ?? json['restaurantsCount']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
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
