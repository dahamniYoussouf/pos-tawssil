class PrinterTemplate {
  final String id;
  final String restaurantId;
  final String? printerId;
  final String name;
  final String type; // 'general', 'caisse', 'cuisine', 'bar'
  final String templateContent;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrinterTemplate({
    required this.id,
    required this.restaurantId,
    this.printerId,
    required this.name,
    required this.type,
    required this.templateContent,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrinterTemplate.fromJson(Map<String, dynamic> json) {
    return PrinterTemplate(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      printerId: json['printer_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      templateContent: json['template_content'] as String,
      isDefault: json['is_default'] == true,
      isActive: json['is_active'] != false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'printer_id': printerId,
      'name': name,
      'type': type,
      'template_content': templateContent,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PrinterTemplate copyWith({
    String? id,
    String? restaurantId,
    String? printerId,
    String? name,
    String? type,
    String? templateContent,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrinterTemplate(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      printerId: printerId ?? this.printerId,
      name: name ?? this.name,
      type: type ?? this.type,
      templateContent: templateContent ?? this.templateContent,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
