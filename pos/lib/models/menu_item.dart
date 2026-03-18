import 'dart:convert';

import 'menu_item_promotion.dart';
import 'addition.dart';
import 'option_group.dart';

class MenuItem {
  final String id;
  final String categoryId;
  final String nom;
  final String? description;
  final double prix;
  final String? photoUrl;
  final bool isAvailable;
  final int tempsPreparation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  final List<Addition> additions;
  final List<OptionGroup> optionGroups;
  final List<MenuItemPromotion> promotions;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.nom,
    this.description,
    required this.prix,
    this.photoUrl,
    this.isAvailable = true,
    this.tempsPreparation = 20,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
    this.additions = const [],
    this.optionGroups = const [],
    this.promotions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'nom': nom,
      'description': description,
      'prix': prix,
      'photo_url': photoUrl,
      'is_available': isAvailable ? 1 : 0,
      'temps_preparation': tempsPreparation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'promotions_json': jsonEncode(promotions.map((p) => p.toMap()).toList()),
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      categoryId: map['category_id'],
      nom: map['nom'] ?? map['name'] ?? '',
      description: map['description'],
      prix: _parseDouble(map['prix']),
      photoUrl: map['photo_url'] ?? map['image_url'] ?? map['image'],
      isAvailable: _parseBool(map['is_available'], fallback: true),
      tempsPreparation: map['temps_preparation'] ?? 20,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      synced: _parseBool(map['synced']),
      additions: const [],
      optionGroups: const [],
      promotions: _decodePromotions(map['promotions_json']),
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      nom: json['nom'] ?? json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? json['desc'],
      prix: _parseDouble(json['prix'] ?? json['price']),
      photoUrl: json['photo_url'] ??
          json['image_url'] ??
          json['image'] ??
          json['photo'],
      isAvailable: _parseBool(
        json['is_available'] ?? json['available'],
        fallback: true,
      ),
      tempsPreparation: json['temps_preparation'] ?? 20,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      synced: true,
      additions: (json['additions'] as List<dynamic>?)
              ?.map((a) => Addition.fromJson(a))
              .toList() ??
          const [],
      optionGroups: (json['option_groups'] as List<dynamic>?)
              ?.map((g) => OptionGroup.fromJson(Map<String, dynamic>.from(g)))
              .toList() ??
          const [],
      promotions: _extractPromotionsFromApi(json),
    );
  }

  MenuItem copyWith({
    String? id,
    String? categoryId,
    String? nom,
    String? description,
    double? prix,
    String? photoUrl,
    bool? isAvailable,
    int? tempsPreparation,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
    List<Addition>? additions,
    List<OptionGroup>? optionGroups,
    List<MenuItemPromotion>? promotions,
  }) {
    return MenuItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      photoUrl: photoUrl ?? this.photoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      tempsPreparation: tempsPreparation ?? this.tempsPreparation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      additions: additions ?? this.additions,
      optionGroups: optionGroups ?? this.optionGroups,
      promotions: promotions ?? this.promotions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'nom': nom,
      'description': description,
      'prix': prix,
      'photo_url': photoUrl,
      'is_available': isAvailable,
      'temps_preparation': tempsPreparation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced,
      'promotions': promotions.map((p) => p.toJson()).toList(),
    };
  }

  MenuItemPromotion? get bestPromotion {
    MenuItemPromotion? selected;
    double? selectedPrice;

    for (final promotion in promotions) {
      if (!promotion.isCurrentlyActive) continue;
      final candidate = promotion.discountedPrice(prix);
      if (candidate == null) continue;
      if (selectedPrice == null || candidate < selectedPrice) {
        selected = promotion;
        selectedPrice = candidate;
      }
    }

    return selected;
  }

  double? get promotionalPrice => bestPromotion?.discountedPrice(prix);

  String? get promotionBadge => bestPromotion?.displayLabel;

  static List<MenuItemPromotion> _decodePromotions(dynamic raw) {
    if (raw == null) return const [];
    try {
      final List<dynamic> decoded = raw is String
          ? jsonDecode(raw) as List<dynamic>
          : (raw as List<dynamic>);
      return decoded
          .map((entry) {
            if (entry is Map<String, dynamic>) {
              return MenuItemPromotion.fromMap(entry);
            }
            if (entry is Map) {
              return MenuItemPromotion.fromMap(
                  Map<String, dynamic>.from(entry));
            }
            return null;
          })
          .whereType<MenuItemPromotion>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<MenuItemPromotion> _extractPromotionsFromApi(
      Map<String, dynamic> json) {
    final merged = <String, MenuItemPromotion>{};
    final sources = [json['promotions'], json['primary_promotions']];

    for (final source in sources) {
      if (source is Iterable) {
        for (final item in source) {
          if (item is Map<String, dynamic>) {
            final promo = MenuItemPromotion.fromJson(item);
            if (promo.id.isNotEmpty) {
              merged[promo.id] = promo;
            }
          } else if (item is Map) {
            final promo =
                MenuItemPromotion.fromJson(Map<String, dynamic>.from(item));
            if (promo.id.isNotEmpty) {
              merged[promo.id] = promo;
            }
          }
        }
      }
    }

    return merged.values.toList();
  }

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return fallback;
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'oui';
    }
    return fallback;
  }

  /// Helper method to safely parse double from dynamic value
  /// Handles both String and num types from API/Database
  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse price: $value');
        return 0.0;
      }
    }

    // Fallback for other num types
    if (value is num) {
      return value.toDouble();
    }

    print('⚠️ Unknown price type: ${value.runtimeType}');
    return 0.0;
  }
}
