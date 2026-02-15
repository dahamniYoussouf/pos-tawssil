import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/categories/models/home_category_model.dart';

class RestaurantStatus {
  static const String open = 'open';
  static const String closed = 'closed';
  static const String vacation = 'vacation';
  static const String saturated = 'saturated';
  static const String other = 'other';
}

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
  final List<HomeCategoryModel>? homeCategories;
  final String? imageUrl;
  final bool? isActive;
  final bool? isApproved;
  final bool? isPremium;
  final double? rating;
  final Map<String, dynamic>? openingHours;
  final String? status;

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
    this.homeCategories,
    this.imageUrl,
    this.isActive,
    this.isApproved,
    this.isPremium,
    this.rating,
    this.openingHours,
    this.status,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['telephone']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      description: json['description']?.toString(),
      address: json['address']?.toString() ?? json['adresse']?.toString(),
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
      homeCategories: json['home_categories'] != null
          ? (json['home_categories'] as List)
              .map((e) => HomeCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['photo_url']?.toString() ??
          json['image']?.toString(),
      isActive: json['is_active'] ?? json['isActive'],
      isApproved: json['is_approved'] ??
          json['isApproved'] ??
          json['approved'] ??
          (json['status'] == 'approved'),
      isPremium: json['is_premium'] ?? json['isPremium'],
      rating: json['rating'] != null
          ? (json['rating'] is num
              ? json['rating'].toDouble()
              : double.tryParse(json['rating'].toString()))
          : null,
      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'])
          : json['openingHours'] != null
              ? Map<String, dynamic>.from(json['openingHours'])
              : null,
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone': phone,
      'description': description,
      'address': address,
      'lat': latitude,
      'lng': longitude,
      'willaya': willaya,
      'zone': zone,
      // Send only category names/IDs as strings as expected by PUT /profile
      'categories': categories?.map((e) => e.nom).toList(),
      'home_categories': homeCategories?.map((e) => e.toJson()).toList(),
      'image_url': imageUrl,
      'is_active': isActive,
      'is_approved': isApproved,
      'is_premium': isPremium,
      'rating': rating,
      'opening_hours': openingHours,
      'status': status,
    };

    // Remove null values to avoid triggering strict backend validators
    data.removeWhere((key, value) => value == null);

    return data;
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
    List<HomeCategoryModel>? homeCategories,
    String? imageUrl,
    bool? isActive,
    bool? isApproved,
    bool? isPremium,
    double? rating,
    Map<String, dynamic>? openingHours,
    String? status,
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
      homeCategories: homeCategories ?? this.homeCategories,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      openingHours: openingHours ?? this.openingHours,
      status: status ?? this.status,
    );
  }

  List<Map<String, dynamic>> get formattedOpeningHours {
    if (openingHours == null || openingHours!.isEmpty) return [];

    final dayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    final List<Map<String, dynamic>> result = [];
    for (var key in dayKeys) {
      final value = openingHours![key] ??
          openingHours![key.substring(0, 3)]; // Support 'monday' or 'mon'
      if (value == null) continue;

      String hours = '';
      bool isClosed = false;

      if (value is String) {
        hours = value;
        isClosed = value.toLowerCase().contains('fermé') ||
            value.toLowerCase().contains('closed');
      } else if (value is Map) {
        if (value['is_closed'] == true || value['closed'] == true) {
          isClosed = true;
          // Note: Label 'Fermé' should be handled by UI via localization
        } else {
          final open = value['open'] ?? value['start'] ?? '';
          final close = value['close'] ?? value['end'] ?? '';
          hours = '$open - $close';
        }
      }

      result.add({
        'dayKey': key,
        'hours': hours,
        'isClosed': isClosed,
      });
    }
    return result;
  }
}
