class DriverModel {
  final String id;
  final String userId;
  final String driverCode;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? email;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? licenseNumber;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? rating;
  final int totalDeliveries;
  final List<dynamic> activeOrders;
  final int maxOrdersCapacity;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastActiveAt;
  final String? notes;
  final int cancellationCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.userId,
    required this.driverCode,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.email,
    this.vehicleType,
    this.vehiclePlate,
    this.licenseNumber,
    required this.status,
    this.latitude,
    this.longitude,
    this.rating,
    required this.totalDeliveries,
    required this.activeOrders,
    required this.maxOrdersCapacity,
    required this.isVerified,
    required this.isActive,
    this.lastActiveAt,
    this.notes,
    required this.cancellationCount,
    required this.createdAt,
    required this.updatedAt,
  });

  String get name {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (firstName.isEmpty) return lastName;
    if (lastName.isEmpty) return firstName;
    return '$firstName $lastName';
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    double? latitude;
    double? longitude;
    final currentLocation = json['current_location'] as Map<String, dynamic>?;
    if (currentLocation != null && currentLocation['type'] == 'Point' && currentLocation['coordinates'] != null) {
      final coords = currentLocation['coordinates'] as List;
      if (coords.length >= 2) {
        longitude = (coords[0] as num).toDouble();
        latitude = (coords[1] as num).toDouble();
      }
    }
    latitude ??= json['latitude'] != null ? (json['latitude'] as num).toDouble() : null;
    longitude ??= json['longitude'] != null ? (json['longitude'] as num).toDouble() : null;
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return DriverModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      driverCode: json['driver_code'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? json['name'] ?? json['nom'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phoneNumber: json['phone'] ?? json['phoneNumber'] ?? json['phone_number'] ?? json['tel'],
      email: json['email'],
      vehicleType: json['vehicle_type'] ?? json['vehicleType'],
      vehiclePlate: json['vehicle_plate'] ?? json['vehiclePlate'],
      licenseNumber: json['license_number'] ?? json['licenseNumber'],
      status: json['status'] ?? 'offline',
      latitude: latitude,
      longitude: longitude,
      rating: json['rating']?.toString(),
      totalDeliveries: json['total_deliveries'] ?? 0,
      activeOrders: json['active_orders'] as List<dynamic>? ?? [],
      maxOrdersCapacity: json['max_orders_capacity'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? false,
      lastActiveAt: parseDateTime(json['last_active_at']),
      notes: json['notes'],
      cancellationCount: json['cancellation_count'] ?? 0,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }
}
