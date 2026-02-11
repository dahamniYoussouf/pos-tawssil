/// Menu item model for restaurant app.
/// Option groups and options align with client-app menu_model for consistency.
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
  final List<MenuItemOptionGroup> optionGroups;

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
    this.optionGroups = const [],
  });

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory MenuItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MenuItemModel(id: '', name: '', price: 0.0);
    }

    final optionGroupsList = json['option_groups'] as List<dynamic>?;
    final optionGroups = optionGroupsList != null
        ? optionGroupsList
            .map((item) =>
                MenuItemOptionGroup.fromJson(item as Map<String, dynamic>))
            .toList()
        : <MenuItemOptionGroup>[];

    return MenuItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      categoryId: json['category_id']?.toString(),
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description']?.toString(),
      price: parseDouble(json['prix'] ?? json['price']),
      preparationTime: parseInt(json['temps_preparation'] ??
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
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      restaurantId: json['restaurant_id']?.toString(),
      optionGroups: optionGroups,
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
      if (optionGroups.isNotEmpty)
        'option_groups':
            optionGroups.map((g) => g.toJson()).toList(),
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
      if (optionGroups.isNotEmpty)
        'option_groups':
            optionGroups.map((g) => g.toJson()).toList(),
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
      if (optionGroups.isNotEmpty)
        'option_groups':
            optionGroups.map((g) => g.toJson()).toList(),
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
    List<MenuItemOptionGroup>? optionGroups,
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
      optionGroups: optionGroups ?? this.optionGroups,
    );
  }
}

/// Option group for a menu item (e.g. "Choice of Crust", "Sauce").
/// Matches client-app MenuItemOptionGroup structure.
class MenuItemOptionGroup {
  final String id;
  final String nom;
  final String? description;
  final bool isRequired;
  final bool multipleChoice;
  final int ordreAffichage;
  final List<MenuItemOption> options;

  MenuItemOptionGroup({
    required this.id,
    required this.nom,
    this.description,
    this.isRequired = false,
    this.multipleChoice = false,
    this.ordreAffichage = 0,
    this.options = const [],
  });

  factory MenuItemOptionGroup.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] as List<dynamic>?;
    final options = optionsList != null
        ? optionsList
            .map(
                (item) => MenuItemOption.fromJson(item as Map<String, dynamic>))
            .toList()
        : <MenuItemOption>[];
    return MenuItemOptionGroup(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      description: json['description'] as String?,
      isRequired: (json['is_required'] ?? json['isRequired']) as bool? ?? false,
      multipleChoice:
          (json['multiple_choice'] ?? json['multipleChoice']) as bool? ?? false,
      ordreAffichage:
          (json['ordre_affichage'] ?? json['ordreAffichage'] ?? 0) as int,
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      'is_required': isRequired,
      'multiple_choice': multipleChoice,
      'ordre_affichage': ordreAffichage,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  MenuItemOptionGroup copyWith({
    String? id,
    String? nom,
    String? description,
    bool? isRequired,
    bool? multipleChoice,
    int? ordreAffichage,
    List<MenuItemOption>? options,
  }) {
    return MenuItemOptionGroup(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      multipleChoice: multipleChoice ?? this.multipleChoice,
      ordreAffichage: ordreAffichage ?? this.ordreAffichage,
      options: options ?? this.options,
    );
  }

  int get optionsCount => options.length;
}

/// Single option within an option group (e.g. "Thin", "0.00 DA").
/// Matches client-app MenuItemOption structure.
class MenuItemOption {
  final String id;
  final String nom;
  final String? description;
  final double prix;
  final bool isAvailable;
  final String? optionGroupId;

  MenuItemOption({
    required this.id,
    required this.nom,
    this.description,
    required this.prix,
    this.isAvailable = true,
    this.optionGroupId,
  });

  factory MenuItemOption.fromJson(Map<String, dynamic> json) {
    return MenuItemOption(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      description: json['description'] as String?,
      prix: MenuItemModel.parseDouble(json['prix'] ?? json['price']),
      isAvailable:
          (json['is_available'] ?? json['isAvailable']) as bool? ?? true,
      optionGroupId:
          (json['option_group_id'] ?? json['optionGroupId']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      'prix': prix,
      'is_available': isAvailable,
      if (optionGroupId != null) 'option_group_id': optionGroupId,
    };
  }

  MenuItemOption copyWith({
    String? id,
    String? nom,
    String? description,
    double? prix,
    bool? isAvailable,
    String? optionGroupId,
  }) {
    return MenuItemOption(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      isAvailable: isAvailable ?? this.isAvailable,
      optionGroupId: optionGroupId ?? this.optionGroupId,
    );
  }

  String get priceFormatted => '${prix.toStringAsFixed(2)} DA';
}
