import 'package:restaurant_app/src/features/categories/models/category_model.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? willaya;
  final String? zone;
  final List<CategoryModel>? categories;
  final String? imageUrl;
  final bool? isActive;
  final Map<String, dynamic>? openingHours;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.willaya,
    this.zone,
    this.categories,
    this.imageUrl,
    this.isActive,
    this.openingHours,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      latitude: json['lat'] != null
          ? (json['lat'] is num
              ? json['lat'].toDouble()
              : double.tryParse(json['lat'].toString()))
          : json['latitude'] != null
              ? (json['latitude'] is num
                  ? json['latitude'].toDouble()
                  : double.tryParse(json['latitude'].toString()))
              : null,
      longitude: json['lng'] != null
          ? (json['lng'] is num
              ? json['lng'].toDouble()
              : double.tryParse(json['lng'].toString()))
          : json['longitude'] != null
              ? (json['longitude'] is num
                  ? json['longitude'].toDouble()
                  : double.tryParse(json['longitude'].toString()))
              : null,
      willaya: json['willaya']?.toString(),
      zone: json['zone']?.toString(),
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((e) => CategoryModel.fromJson(e is Map<String, dynamic>
                  ? e
                  : {
                      'id': e.toString(),
                      'nom': e.toString(),
                      'description': '',
                      'ordre_affichage': 0,
                      'items': [],
                      'items_count': 0
                    }))
              .toList()
          : null,
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      isActive: json['is_active'] ?? json['isActive'],
      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'])
          : json['openingHours'] != null
              ? Map<String, dynamic>.from(json['openingHours'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'description': description,
      'address': address,
      'lat': latitude,
      'lng': longitude,
      'willaya': willaya,
      'zone': zone,
      'categories': categories,
      'image_url': imageUrl,
      'is_active': isActive,
      'opening_hours': openingHours,
    };
  }

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? willaya,
    String? zone,
    List<CategoryModel>? categories,
    String? imageUrl,
    bool? isActive,
    Map<String, dynamic>? openingHours,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      willaya: willaya ?? this.willaya,
      zone: zone ?? this.zone,
      categories: categories ?? this.categories,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      openingHours: openingHours ?? this.openingHours,
    );
  }
}
