class OrderStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String preparing = 'preparing';
  static const String assigned = 'assigned';
  static const String delivering = 'delivering';
  static const String delivered = 'delivered';
  static const String refused = 'refused';
  static const String delayed = 'delayed';
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Handle nested menu_item structure
    final menuItem = json['menu_item'] as Map<String, dynamic>?;
    final String name;
    final double price;
    if (menuItem != null) {
      name = menuItem['nom'] ?? menuItem['name'] ?? '';
      price = parseDouble(menuItem['prix'] ?? menuItem['price'] ?? json['prix_unitaire'] ?? json['price']);
    } else {
      name = json['name'] ?? json['nom'] ?? '';
      price = parseDouble(json['price'] ?? json['prix'] ?? json['prix_unitaire']);
    }
    return OrderItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: name,
      quantity: json['quantity'] ?? json['quantite'] ?? 1,
      price: price,
    );
  }

  double get totalPrice => price * quantity;
}

class DeliveryPerson {
  final String id;
  final String name;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  DeliveryPerson({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DeliveryPerson(id: '', name: '');
    }
    return DeliveryPerson(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? json['nom'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? json['tel'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItem> items;
  final double totalPrice;
  final String? deliveryAddress;
  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? restaurantName;
  final DeliveryPerson? deliveryPerson;
  final DateTime? estimatedDeliveryTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? refusalReason;
  final String? delayReason;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.totalPrice,
    this.deliveryAddress,
    this.restaurantLatitude,
    this.restaurantLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.restaurantName,
    this.deliveryPerson,
    this.estimatedDeliveryTime,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.refusalReason,
    this.delayReason,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items - handle order_items array
    final itemsList = json['items'] ?? json['orderItems'] ?? json['order_items'] ?? [];
    final List<OrderItem> items = (itemsList as List).map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList();

    // Parse delivery person (driver)
    DeliveryPerson? deliveryPerson;
    if (json['driver'] != null) {
      deliveryPerson = DeliveryPerson.fromJson(json['driver'] as Map<String, dynamic>?);
    } else if (json['deliveryPerson'] != null || json['delivery_person'] != null) {
      deliveryPerson = DeliveryPerson.fromJson(
        (json['deliveryPerson'] ?? json['delivery_person']) as Map<String, dynamic>?,
      );
    }

    // Helper function to parse GeoJSON Point coordinates
    // GeoJSON format: {type: "Point", coordinates: [longitude, latitude]}
    List<double>? parseGeoJsonPoint(Map<String, dynamic>? location) {
      if (location == null) return null;
      if (location['type'] == 'Point' && location['coordinates'] != null) {
        final coords = location['coordinates'] as List;
        if (coords.length >= 2) {
          return [
            (coords[0] as num).toDouble(), // longitude
            (coords[1] as num).toDouble(), // latitude
          ];
        }
      }
      return null;
    }

    // Parse restaurant location from GeoJSON Point
    double? restaurantLat;
    double? restaurantLng;
    if (json['restaurant'] != null) {
      final restaurant = json['restaurant'] is Map ? json['restaurant'] as Map<String, dynamic> : null;
      if (restaurant != null) {
        final location = restaurant['location'] as Map<String, dynamic>?;
        final coords = parseGeoJsonPoint(location);
        if (coords != null) {
          restaurantLng = coords[0];
          restaurantLat = coords[1];
        } else {
          restaurantLat = restaurant['latitude'] != null ? (restaurant['latitude'] as num).toDouble() : null;
          restaurantLng = restaurant['longitude'] != null ? (restaurant['longitude'] as num).toDouble() : null;
        }
      }
    }
    restaurantLat ??= json['restaurantLatitude'] != null ? (json['restaurantLatitude'] as num).toDouble() : null;
    restaurantLng ??= json['restaurantLongitude'] != null ? (json['restaurantLongitude'] as num).toDouble() : null;

    // Parse delivery location from GeoJSON Point
    double? deliveryLat;
    double? deliveryLng;
    final deliveryLocation = json['deliveryLocation'] ?? json['delivery_location'];
    if (deliveryLocation != null) {
      final location = deliveryLocation is Map ? deliveryLocation as Map<String, dynamic> : null;
      final coords = parseGeoJsonPoint(location);
      if (coords != null) {
        deliveryLng = coords[0];
        deliveryLat = coords[1];
      } else {
        deliveryLat = location?['latitude'] != null ? (location!['latitude'] as num).toDouble() : null;
        deliveryLng = location?['longitude'] != null ? (location!['longitude'] as num).toDouble() : null;
      }
    }
    deliveryLat ??= json['deliveryLatitude'] != null ? (json['deliveryLatitude'] as num).toDouble() : null;
    deliveryLng ??= json['deliveryLongitude'] != null ? (json['deliveryLongitude'] as num).toDouble() : null;

    // Parse restaurant name
    String? restaurantName;
    restaurantName = json['restaurantName'] ?? json['restaurant_name'];
    if (restaurantName == null && json['restaurant'] != null) {
      final restaurant = json['restaurant'] is Map ? json['restaurant'] as Map<String, dynamic> : null;
      if (restaurant != null) {
        restaurantName = restaurant['name'] ?? restaurant['nom'];
      }
    }

    // Parse dates
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return OrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      orderNumber: json['orderNumber'] ?? json['order_number'] ?? json['number'] ?? '',
      status: json['status'] ?? OrderStatus.pending,
      items: items,
      totalPrice: parseDouble(json['totalPrice'] ?? json['total_price'] ?? json['total_amount'] ?? json['total']),
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'] ?? json['address'],
      restaurantLatitude: restaurantLat,
      restaurantLongitude: restaurantLng,
      deliveryLatitude: deliveryLat,
      deliveryLongitude: deliveryLng,
      restaurantName: restaurantName,
      deliveryPerson: deliveryPerson,
      estimatedDeliveryTime: parseDate(json['estimatedDeliveryTime'] ?? json['estimated_delivery_time']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      refusalReason: json['refusalReason'] ?? json['refusal_reason'] ?? json['decline_reason'],
      delayReason: json['delayReason'] ?? json['delay_reason'],
    );
  }

  bool get isDelivering => status == OrderStatus.delivering;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isRefused => status == OrderStatus.refused;
  bool get isDelayed => status == OrderStatus.delayed;
}
