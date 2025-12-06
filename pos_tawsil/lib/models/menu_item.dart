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
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      categoryId: map['category_id'],
      nom: map['nom'],
      description: map['description'],
      prix: _parseDouble(map['prix']),
      photoUrl: map['photo_url'],
      isAvailable: map['is_available'] == 1,
      tempsPreparation: map['temps_preparation'] ?? 20,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      synced: map['synced'] == 1,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      prix: _parseDouble(json['prix']),
      photoUrl: json['photo_url'],
      isAvailable: json['is_available'] ?? true,
      tempsPreparation: json['temps_preparation'] ?? 20,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      synced: true,
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
    };
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