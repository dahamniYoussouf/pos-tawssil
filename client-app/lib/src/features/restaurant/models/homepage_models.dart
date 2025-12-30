import 'restaurant_model.dart';
import 'menu_model.dart';

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
      imageUrl: json['image_url'] as String?,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? json['displayOrder'] ?? 0) as int,
      restaurantsCount:
          (json['restaurants_count'] ?? json['restaurantsCount'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
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

class ThematicSelectionModel {
  final String id;
  final String name;
  final String? description;
  final String? homeCategoryId;
  final String? imageUrl;
  final bool isActive;
  final int restaurantsCount;
  final HomeCategoryModel? homeCategory;
  final List<RestaurantModel> restaurants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ThematicSelectionModel({
    required this.id,
    required this.name,
    this.description,
    this.homeCategoryId,
    this.imageUrl,
    required this.isActive,
    required this.restaurantsCount,
    this.homeCategory,
    this.restaurants = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ThematicSelectionModel.fromJson(Map<String, dynamic> json) {
    final restaurantsList = json['restaurants'] as List<dynamic>? ?? [];
    final restaurants = restaurantsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return RestaurantModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<RestaurantModel>()
        .toList();

    return ThematicSelectionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      homeCategoryId: json['home_category_id'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      restaurantsCount:
          (json['restaurants_count'] ?? json['restaurantsCount'] ?? 0) as int,
      homeCategory: json['home_category'] != null
          ? HomeCategoryModel.fromJson(
              json['home_category'] as Map<String, dynamic>)
          : null,
      restaurants: restaurants,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (homeCategoryId != null) 'home_category_id': homeCategoryId,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': isActive,
      'restaurants_count': restaurantsCount,
      if (homeCategory != null) 'home_category': homeCategory!.toJson(),
      'restaurants': restaurants.map((r) => r.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class RecommendedDishModel {
  final String id;
  final String restaurantId;
  final String menuItemId;
  final String? reason;
  final bool isActive;
  final RestaurantModel? restaurant;
  final MenuItemBasicInfo? menuItem;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RecommendedDishModel({
    required this.id,
    required this.restaurantId,
    required this.menuItemId,
    this.reason,
    required this.isActive,
    this.restaurant,
    this.menuItem,
    this.createdAt,
    this.updatedAt,
  });

  factory RecommendedDishModel.fromJson(Map<String, dynamic> json) {
    return RecommendedDishModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      restaurantId: (json['restaurant_id'] ?? '').toString(),
      menuItemId: (json['menu_item_id'] ?? '').toString(),
      reason: json['reason'] as String?,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      restaurant: json['restaurant'] != null
          ? RestaurantModel.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      menuItem: json['menu_item'] != null
          ? MenuItemBasicInfo.fromJson(
              json['menu_item'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'menu_item_id': menuItemId,
      if (reason != null) 'reason': reason,
      'is_active': isActive,
      if (restaurant != null) 'restaurant': restaurant!.toJson(),
      if (menuItem != null) 'menu_item': menuItem!.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class MenuItemBasicInfo {
  final String id;
  final String nom;
  final double prix;
  final String? photoUrl;

  MenuItemBasicInfo({
    required this.id,
    required this.nom,
    required this.prix,
    this.photoUrl,
  });

  factory MenuItemBasicInfo.fromJson(Map<String, dynamic> json) {
    return MenuItemBasicInfo(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      prix: MenuModel.parsePrice(json['prix'] ?? json['price'] ?? 0),
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}

class DailyDealModel {
  final String id;
  final String promotionId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final PromotionModel promotion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyDealModel({
    required this.id,
    required this.promotionId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.promotion,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyDealModel.fromJson(Map<String, dynamic> json) {
    return DailyDealModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      promotionId: (json['promotion_id'] ?? '').toString(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      promotion:
          PromotionModel.fromJson(json['promotion'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotion_id': promotionId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'promotion': promotion.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class PromotionModel {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String scope;
  final String? restaurantId;
  final String? menuItemId;
  final String? discountValue;
  final String? currency;
  final String? badgeText;
  final String? customMessage;
  final int? buyQuantity;
  final int? freeQuantity;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final RestaurantBasicInfo? restaurant;
  final MenuItemBasicInfo? menuItem;
  final List<MenuItemBasicInfo> menuItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PromotionModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.scope,
    this.restaurantId,
    this.menuItemId,
    this.discountValue,
    this.currency,
    this.badgeText,
    this.customMessage,
    this.buyQuantity,
    this.freeQuantity,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.metadata,
    this.restaurant,
    this.menuItem,
    this.menuItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    final menuItemsList = json['menu_items'] as List<dynamic>? ?? [];
    final menuItems = menuItemsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return MenuItemBasicInfo.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<MenuItemBasicInfo>()
        .toList();

    return PromotionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      type: (json['type'] ?? '').toString(),
      scope: (json['scope'] ?? '').toString(),
      restaurantId: json['restaurant_id'] as String?,
      menuItemId: json['menu_item_id'] as String?,
      discountValue: json['discount_value']?.toString(),
      currency: json['currency'] as String?,
      badgeText: json['badge_text'] as String?,
      customMessage: json['custom_message'] as String?,
      buyQuantity: json['buy_quantity'] as int?,
      freeQuantity: json['free_quantity'] as int?,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
      restaurant: json['restaurant'] != null
          ? RestaurantBasicInfo.fromJson(
              json['restaurant'] as Map<String, dynamic>)
          : null,
      menuItem: json['menu_item'] != null
          ? MenuItemBasicInfo.fromJson(
              json['menu_item'] as Map<String, dynamic>)
          : null,
      menuItems: menuItems,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'type': type,
      'scope': scope,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      if (discountValue != null) 'discount_value': discountValue,
      if (currency != null) 'currency': currency,
      if (badgeText != null) 'badge_text': badgeText,
      if (customMessage != null) 'custom_message': customMessage,
      if (buyQuantity != null) 'buy_quantity': buyQuantity,
      if (freeQuantity != null) 'free_quantity': freeQuantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      if (metadata != null) 'metadata': metadata,
      if (restaurant != null) 'restaurant': restaurant!.toJson(),
      if (menuItem != null) 'menu_item': menuItem!.toJson(),
      'menu_items': menuItems.map((item) => item.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class RestaurantBasicInfo {
  final String id;
  final String name;
  final bool? isPremium;
  final String? imageUrl;

  RestaurantBasicInfo({
    required this.id,
    required this.name,
    this.isPremium,
    this.imageUrl,
  });

  factory RestaurantBasicInfo.fromJson(Map<String, dynamic> json) {
    return RestaurantBasicInfo(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isPremium: json['is_premium'] as bool?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (isPremium != null) 'is_premium': isPremium,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String? content;
  final String? cssStyles;
  final String? jsScripts;
  final String type;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final String? restaurantId;
  final RestaurantBasicInfo? restaurant;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? image;

  AnnouncementModel(
      {required this.id,
      required this.title,
      this.content,
      this.cssStyles,
      this.jsScripts,
      required this.type,
      required this.isActive,
      required this.startDate,
      required this.endDate,
      this.restaurantId,
      this.restaurant,
      this.createdAt,
      this.updatedAt,
      this.image});

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: json['content'] as String?,
      cssStyles: json['css_styles'] as String?,
      jsScripts: json['js_scripts'] as String?,
      type: (json['type'] ?? 'info').toString(),
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      restaurantId: json['restaurant_id'] as String?,
      image: json['image_url'] as String?,
      restaurant: json['restaurant'] != null
          ? RestaurantBasicInfo.fromJson(
              json['restaurant'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (content != null) 'content': content,
      if (cssStyles != null) 'css_styles': cssStyles,
      if (jsScripts != null) 'js_scripts': jsScripts,
      'type': type,
      'is_active': isActive,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (restaurant != null) 'restaurant': restaurant!.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (image != null) 'image_url': image.toString(),
    };
  }
}

class NearbyRestaurantsData {
  final int count;
  final int page;
  final int pageSize;
  final int radius;
  final Map<String, double> center;
  final String searchType;
  final List<RestaurantModel> data;

  NearbyRestaurantsData({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.radius,
    required this.center,
    required this.searchType,
    required this.data,
  });

  factory NearbyRestaurantsData.fromJson(Map<String, dynamic> json) {
    final centerMap = json['center'] as Map<String, dynamic>? ?? {};
    final dataList = json['data'] as List<dynamic>? ?? [];
    final restaurants = dataList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return RestaurantModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<RestaurantModel>()
        .toList();

    return NearbyRestaurantsData(
      count: (json['count'] ?? 0) as int,
      page: (json['page'] ?? 1) as int,
      pageSize: (json['pageSize'] ?? 20) as int,
      radius: (json['radius'] ?? 2500) as int,
      center: {
        'lat': (centerMap['lat'] ?? 0.0) as double,
        'lng': (centerMap['lng'] ?? 0.0) as double,
      },
      searchType: (json['searchType'] ?? 'coordinates').toString(),
      data: restaurants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'page': page,
      'pageSize': pageSize,
      'radius': radius,
      'center': center,
      'searchType': searchType,
      'data': data.map((r) => r.toJson()).toList(),
    };
  }
}

class HomepageDataModel {
  final List<HomeCategoryModel> homeCategories;
  final List<ThematicSelectionModel> thematicSelections;
  final List<RecommendedDishModel> recommendedDishes;
  final List<DailyDealModel> dailyDeals;
  final List<PromotionModel> promotions;
  final List<AnnouncementModel> announcements;
  final List<RestaurantModel> featuredRestaurants;
  final NearbyRestaurantsData? nearby;

  HomepageDataModel({
    this.homeCategories = const [],
    this.thematicSelections = const [],
    this.recommendedDishes = const [],
    this.dailyDeals = const [],
    this.promotions = const [],
    this.announcements = const [],
    this.featuredRestaurants = const [],
    this.nearby,
  });

  factory HomepageDataModel.fromJson(Map<String, dynamic> json) {
    final homeCategoriesList = json['homeCategories'] as List<dynamic>? ?? [];
    final homeCategories = homeCategoriesList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return HomeCategoryModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<HomeCategoryModel>()
        .toList();

    final thematicSelectionsList =
        json['thematicSelections'] as List<dynamic>? ?? [];
    final thematicSelections = thematicSelectionsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return ThematicSelectionModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<ThematicSelectionModel>()
        .toList();

    final recommendedDishesList =
        json['recommendedDishes'] as List<dynamic>? ?? [];
    final recommendedDishes = recommendedDishesList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return RecommendedDishModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<RecommendedDishModel>()
        .toList();

    final dailyDealsList = json['dailyDeals'] as List<dynamic>? ?? [];
    final dailyDeals = dailyDealsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return DailyDealModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<DailyDealModel>()
        .toList();

    final promotionsList = json['promotions'] as List<dynamic>? ?? [];
    final promotions = promotionsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return PromotionModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<PromotionModel>()
        .toList();

    final announcementsList = json['announcements'] as List<dynamic>? ?? [];
    final announcements = announcementsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return AnnouncementModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<AnnouncementModel>()
        .toList();

    final featuredRestaurantsList =
        json['featuredRestaurants'] as List<dynamic>? ?? [];
    final featuredRestaurants = featuredRestaurantsList
        .map((e) {
          try {
            if (e is Map<String, dynamic>) {
              return RestaurantModel.fromJson(e);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<RestaurantModel>()
        .toList();

    return HomepageDataModel(
      homeCategories: homeCategories,
      thematicSelections: thematicSelections,
      recommendedDishes: recommendedDishes,
      dailyDeals: dailyDeals,
      promotions: promotions,
      announcements: announcements,
      featuredRestaurants: featuredRestaurants,
      nearby: json['nearby'] != null
          ? NearbyRestaurantsData.fromJson(
              json['nearby'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeCategories': homeCategories.map((c) => c.toJson()).toList(),
      'thematicSelections': thematicSelections.map((t) => t.toJson()).toList(),
      'recommendedDishes': recommendedDishes.map((d) => d.toJson()).toList(),
      'dailyDeals': dailyDeals.map((d) => d.toJson()).toList(),
      'promotions': promotions.map((p) => p.toJson()).toList(),
      'announcements': announcements.map((a) => a.toJson()).toList(),
      'featuredRestaurants':
          featuredRestaurants.map((r) => r.toJson()).toList(),
      if (nearby != null) 'nearby': nearby!.toJson(),
    };
  }
}
