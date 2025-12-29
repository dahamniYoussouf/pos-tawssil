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
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // Helper to read nested location objects that some APIs may return
    Map<String, dynamic>? _locationMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      return null;
    }

    // Try multiple common key names used across schema versions
    final id = (json['id'] ?? json['_id'] ?? json['restaurant_id'] ?? '') as dynamic;
    final name = (json['name'] ?? json['nom'] ?? json['title'] ?? '') as dynamic;
    final description = (json['description'] ?? json['desc'] ?? json['description_fr'] ?? json['description_ar'] ?? '') as dynamic;
    final imageUrl = (json['image_url'] ?? json['imageUrl'] ?? json['image'] ?? json['photo'] ?? json['picture'] ?? '') as dynamic;

    // rating may be named differently or be a string
    final ratingVal = json['rating'] ?? json['avg_rating'] ?? json['average_rating'] ?? json['note'] ?? 0.0;

    // delivery times - try several names and parse to int safely
    final deliveryMinVal = json['delivery_time_min'] ?? json['delivery_min'] ?? json['deliveryMin'] ?? json['min_delivery_time'];
    final deliveryMaxVal = json['delivery_time_max'] ?? json['delivery_max'] ?? json['deliveryMax'] ?? json['max_delivery_time'];

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

    final isPremiumVal = _parseBool(json['is_premium'] ?? json['isPremium'] ?? json['premium'] ?? json['is_vip']);
    final deliveryFeeVal = json['delivery_fee'] ?? json['deliveryFee'] ?? null;
    final promotionBadgeTextVal = json['promotion_badge_text'] ?? json['promotionBadgeText'] as String?;

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
      if (promotionBadgeText != null) 'promotion_badge_text': promotionBadgeText,
    };
  }
}
