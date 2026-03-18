import 'addition.dart';

class OptionGroup {
  final String id;
  final String menuItemId;
  final String nom;
  final String? description;
  final bool isRequired;
  final int? ordreAffichage;
  final List<Addition> additions;

  OptionGroup({
    required this.id,
    required this.menuItemId,
    required this.nom,
    this.description,
    this.isRequired = false,
    this.ordreAffichage,
    this.additions = const [],
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    final rawAdditions =
        (json['additions'] ?? json['options']) as List<dynamic>? ?? const [];
    return OptionGroup(
      id: json['id'] ?? '',
      menuItemId: json['menu_item_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      isRequired: _parseBool(json['is_required']),
      ordreAffichage: json['ordre_affichage'] is int
          ? json['ordre_affichage']
          : int.tryParse(json['ordre_affichage']?.toString() ?? ''),
      additions: rawAdditions
          .map((entry) => Addition.fromJson(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }

  factory OptionGroup.fromMap(Map<String, dynamic> map) {
    return OptionGroup(
      id: map['id'] ?? '',
      menuItemId: map['menu_item_id'] ?? '',
      nom: map['nom'] ?? '',
      description: map['description'],
      isRequired: map['is_required'] == 1 || map['is_required'] == true,
      ordreAffichage: map['ordre_affichage'] is int
          ? map['ordre_affichage']
          : int.tryParse(map['ordre_affichage']?.toString() ?? ''),
      additions: const [],
    );
  }

  OptionGroup copyWith({List<Addition>? additions}) {
    return OptionGroup(
      id: id,
      menuItemId: menuItemId,
      nom: nom,
      description: description,
      isRequired: isRequired,
      ordreAffichage: ordreAffichage,
      additions: additions ?? this.additions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'nom': nom,
      'description': description,
      'is_required': isRequired ? 1 : 0,
      'ordre_affichage': ordreAffichage,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
