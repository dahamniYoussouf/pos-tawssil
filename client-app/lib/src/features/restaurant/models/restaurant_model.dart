import 'homepage_models.dart';

class RestaurantMenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int? prepTimeMinutes;

  RestaurantMenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    this.prepTimeMinutes,
  });

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      price: _parseDouble(json['price'] ?? 0),
      imageUrl: json['image_url'] as String?,
      isAvailable:
          _parseBool(json['is_available'] ?? json['isAvailable'] ?? true),
      prepTimeMinutes:
          _parseInt(json['prep_time_minutes'] ?? json['prepTimeMinutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_available': isAvailable,
      if (prepTimeMinutes != null) 'prep_time_minutes': prepTimeMinutes,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes' || v == 'y';
    }
    return false;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int deliveryMin;
  final int deliveryMax;
  final String? address;
  final double? distance;
  final double? lat;
  final double? lng;
  final bool isPremium;
  final double? deliveryFee;
  final String? promotionBadgeText;
  final List<HomeCategoryModel> homeCategories;
  final int? ratingCount;
  final int? ratersCount;
  final String? status;
  final bool isOpen;
  final List<String> categories;
  final String? favoriteUuid;
  final String? email;
  final List<RestaurantMenuItem> menuItems;
  final List<PromotionModel> promotions;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.deliveryMin,
    required this.deliveryMax,
    this.address,
    this.distance,
    this.lat,
    this.lng,
    required this.isPremium,
    this.deliveryFee,
    this.promotionBadgeText,
    this.homeCategories = const [],
    this.ratingCount,
    this.ratersCount,
    this.status,
    this.isOpen = false,
    this.categories = const [],
    this.favoriteUuid,
    this.email,
    this.menuItems = const [],
    this.promotions = const [],
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // Helper to read nested location objects that some APIs may return
    Map<String, dynamic>? _locationMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      return null;
    }

    // Try multiple common key names used across schema versions
    final id =
        (json['id'] ?? json['_id'] ?? json['restaurant_id'] ?? '') as dynamic;
    final name =
        (json['name'] ?? json['nom'] ?? json['title'] ?? '') as dynamic;
    final description = (json['description'] ??
        json['desc'] ??
        json['description_fr'] ??
        json['description_ar'] ??
        '') as dynamic;
    final imageUrl = (json['image_url'] ??
        json['imageUrl'] ??
        json['image'] ??
        json['photo'] ??
        json['picture'] ??
        '') as dynamic;

    // rating may be named differently or be a string
    final ratingVal = json['rating'] ??
        json['avg_rating'] ??
        json['average_rating'] ??
        json['note'] ??
        0.0;

    // delivery times - try several names and parse to int safely
    final deliveryMinVal = json['delivery_time_min'] ??
        json['delivery_min'] ??
        json['deliveryMin'] ??
        json['min_delivery_time'];
    final deliveryMaxVal = json['delivery_time_max'] ??
        json['delivery_max'] ??
        json['deliveryMax'] ??
        json['max_delivery_time'];

    // address/distance
    final addressVal = json['address'] ?? json['adresse'] ?? null;
    final distanceVal = json['distance'] ?? json['dist'] ?? null;

    // lat/lng may be top-level or inside a 'location' object, or named latitude/longitude
    double? latVal;
    double? lngVal;
    if (json['lat'] != null || json['lng'] != null) {
      latVal = _parseDouble(json['lat']);
      lngVal = _parseDouble(json['lng']);
    } else if (json['latitude'] != null || json['longitude'] != null) {
      latVal = _parseDouble(json['latitude']);
      lngVal = _parseDouble(json['longitude']);
    } else if (json['location'] != null) {
      final loc = _locationMap(json['location']);
      if (loc != null) {
        latVal = _parseDouble(loc['lat'] ?? loc['latitude']);
        lngVal = _parseDouble(loc['lng'] ?? loc['longitude']);
      }
    }

    final isPremiumVal = _parseBool(json['is_premium'] ??
        json['isPremium'] ??
        json['premium'] ??
        json['is_vip']);
    final deliveryFeeVal = json['delivery_fee'] ?? json['deliveryFee'] ?? null;
    final promotionBadgeTextVal =
        json['promotion_badge_text'] ?? json['promotionBadgeText'] as String?;

    // Parse home_categories array
    final homeCategoriesList =
        json['home_categories'] ?? json['homeCategories'] ?? [];
    final List<HomeCategoryModel> homeCategories = [];
    if (homeCategoriesList is List) {
      for (var item in homeCategoriesList) {
        if (item is Map<String, dynamic>) {
          try {
            homeCategories.add(HomeCategoryModel.fromJson(item));
          } catch (e) {
            // Skip invalid category items
          }
        }
      }
    }

    // Parse rating_count and raters_count
    final ratingCountVal = json['rating_count'] ?? json['ratingCount'];
    final ratersCountVal = json['raters_count'] ?? json['ratersCount'];

    int? _parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Parse status and is_open
    final statusVal = json['status'] as String?;
    final isOpenVal = _parseBool(json['is_open'] ?? json['isOpen'] ?? false);

    // Parse categories array
    final categoriesList = json['categories'] ?? [];
    final List<String> categories = [];
    if (categoriesList is List) {
      for (var item in categoriesList) {
        if (item != null) {
          categories.add(item.toString());
        }
      }
    }

    // Parse favorite_uuid and email
    final favoriteUuidVal =
        json['favorite_uuid'] ?? json['favoriteUuid'] as String?;
    final emailVal = json['email'] as String?;

    // Parse menu_items array
    final menuItemsList = json['menu_items'] ?? json['menuItems'] ?? [];
    final List<RestaurantMenuItem> menuItems = [];
    if (menuItemsList is List) {
      for (var item in menuItemsList) {
        if (item is Map<String, dynamic>) {
          try {
            menuItems.add(RestaurantMenuItem.fromJson(item));
          } catch (e) {
            // Skip invalid menu item
          }
        }
      }
    }

    // Parse promotions array
    final promotionsList = json['promotions'] ?? [];
    final List<PromotionModel> promotions = [];
    if (promotionsList is List) {
      for (var item in promotionsList) {
        if (item is Map<String, dynamic>) {
          try {
            promotions.add(PromotionModel.fromJson(item));
          } catch (e) {
            // Skip invalid promotion
          }
        }
      }
    }

    return RestaurantModel(
      id: id?.toString() ?? '',
      name: name?.toString() ?? '',
      description: description?.toString() ?? '',
      imageUrl: imageUrl?.toString() ?? '',
      rating: _parseDouble(ratingVal),
      deliveryMin: _parseInt(deliveryMinVal),
      deliveryMax: _parseInt(deliveryMaxVal),
      address: addressVal?.toString(),
      distance: distanceVal != null ? _parseDouble(distanceVal) : null,
      lat: latVal,
      lng: lngVal,
      isPremium: isPremiumVal,
      deliveryFee: deliveryFeeVal != null ? _parseDouble(deliveryFeeVal) : null,
      promotionBadgeText: promotionBadgeTextVal?.toString(),
      homeCategories: homeCategories,
      ratingCount: _parseIntNullable(ratingCountVal),
      ratersCount: _parseIntNullable(ratersCountVal),
      status: statusVal,
      isOpen: isOpenVal,
      categories: categories,
      favoriteUuid: favoriteUuidVal?.toString(),
      email: emailVal?.toString(),
      menuItems: menuItems,
      promotions: promotions,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes' || v == 'y';
    }
    return false;
  }

  get Price => null;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'delivery_time_min': deliveryMin,
      'delivery_time_max': deliveryMax,
      'address': address,
      'distance': distance,
      'lat': lat,
      'lng': lng,
      'is_premium': isPremium,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (promotionBadgeText != null)
        'promotion_badge_text': promotionBadgeText,
      if (homeCategories.isNotEmpty)
        'home_categories': homeCategories.map((c) => c.toJson()).toList(),
      if (ratingCount != null) 'rating_count': ratingCount,
      if (ratersCount != null) 'raters_count': ratersCount,
      if (status != null) 'status': status,
      'is_open': isOpen,
      if (categories.isNotEmpty) 'categories': categories,
      if (favoriteUuid != null) 'favorite_uuid': favoriteUuid,
      if (email != null) 'email': email,
      if (menuItems.isNotEmpty)
        'menu_items': menuItems.map((item) => item.toJson()).toList(),
      if (promotions.isNotEmpty)
        'promotions': promotions.map((p) => p.toJson()).toList(),
    };
  }
}
