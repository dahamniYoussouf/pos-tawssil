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
    // Handle lat/lng as either string or number
    double parseCoordinate(dynamic value) {
      if (value == null) throw ArgumentError('Coordinate cannot be null');
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null) {
          throw FormatException('Invalid coordinate format: $value');
        }
        return parsed;
      }
      throw FormatException('Coordinate must be a number or string, got: ${value.runtimeType}');
    }

    // Try to get coordinates from lat/lng fields first
    double? lat;
    double? lng;

    if (json['lat'] != null && json['lng'] != null) {
      lat = parseCoordinate(json['lat']);
      lng = parseCoordinate(json['lng']);
    } else if (json['location'] != null) {
      // Fallback to GeoJSON format: location.coordinates = [lng, lat]
      final location = json['location'] as Map<String, dynamic>?;
      if (location != null && location['coordinates'] != null) {
        final coordinates = location['coordinates'] as List<dynamic>?;
        if (coordinates != null && coordinates.length >= 2) {
          // GeoJSON format: [longitude, latitude]
          lng = parseCoordinate(coordinates[0]);
          lat = parseCoordinate(coordinates[1]);
        }
      }
    }

    if (lat == null || lng == null) {
      throw FormatException('Missing coordinates in address data');
    }

    return FavoriteAddressModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: lat,
      lng: lng,
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

