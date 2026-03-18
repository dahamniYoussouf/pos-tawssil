class MenuItemPromotion {
  final String id;
  final String type;
  final double? discountValue;
  final String currency;
  final String? badgeText;
  final String? title;
  final String? description;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const MenuItemPromotion({
    required this.id,
    required this.type,
    this.discountValue,
    this.currency = 'DZD',
    this.badgeText,
    this.title,
    this.description,
    this.isActive = false,
    this.startDate,
    this.endDate,
  });

  factory MenuItemPromotion.fromJson(Map<String, dynamic> json) {
    return MenuItemPromotion(
      id: json['id']?.toString() ?? '',
      type: (json['type'] as String?)?.toLowerCase() ?? 'other',
      discountValue: _parseDouble(json['discount_value']),
      currency: (json['currency'] as String?) ?? 'DZD',
      badgeText: json['badge_text'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      isActive: _parseBool(json['is_active']),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
    );
  }

  factory MenuItemPromotion.fromMap(Map<String, dynamic> map) {
    return MenuItemPromotion(
      id: map['id']?.toString() ?? '',
      type: (map['type'] as String?)?.toLowerCase() ?? 'other',
      discountValue: _parseDouble(map['discount_value']),
      currency: (map['currency'] as String?) ?? 'DZD',
      badgeText: map['badge_text'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      isActive: _parseBool(map['is_active']),
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'discount_value': discountValue,
      'currency': currency,
      'badge_text': badgeText,
      'title': title,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  double? discountedPrice(double basePrice) {
    if (discountValue == null) return null;
    if (!basePrice.isFinite) return null;

    switch (type) {
      case 'percentage':
        final result = basePrice * (1 - discountValue! / 100);
        return result.clamp(0.0, double.infinity);
      case 'amount':
        final result = basePrice - discountValue!;
        return result >= 0 ? result : 0;
      default:
        return null;
    }
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  String? get displayLabel => badgeText ?? title;

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
