class FavoriteAddressModel {
  final String? id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool isDefault;

  const FavoriteAddressModel({
    this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  factory FavoriteAddressModel.fromJson(Map<String, dynamic> json) {
    return FavoriteAddressModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }

  FavoriteAddressModel copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    bool? isDefault,
  }) {
    return FavoriteAddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

