import 'client_model.dart';

class OrderStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String preparing = 'preparing';
  static const String assigned = 'assigned';
  static const String arrived = 'arrived';
  static const String delivering = 'delivering';
  static const String delivered = 'delivered';
  static const String declined = 'declined';
  static const String delayed = 'delayed';
  static const String readyToCollect = 'readyToCollect';
  static const String collected = 'collected';
}

class MenuItem {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;
  final bool isAvailable;
  final int? preparationTimeMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? restaurantId;

  MenuItem({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.photoUrl,
    this.isAvailable = true,
    this.preparationTimeMinutes,
    this.createdAt,
    this.updatedAt,
    this.restaurantId,
  });

  factory MenuItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MenuItem(id: '', name: '', price: 0.0);
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

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

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    return MenuItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      categoryId: json['category_id']?.toString(),
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description'],
      price: parseDouble(json['prix'] ?? json['price']),
      photoUrl: json['photo_url'] ??
          json['photoUrl'] ??
          json['image'] ??
          json['image_url'],
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
      preparationTimeMinutes: parseInt(json['temps_preparation'] ??
          json['preparation_time'] ??
          json['preparationTimeMinutes']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      restaurantId: json['restaurant_id']?.toString(),
    );
  }
}

class OrderItem {
  final String id;
  final String? orderId;
  final String? menuItemId;
  final String name;
  final int quantity;
  final double price;
  final double? _totalPriceValue;
  final String? imageUrl;
  final String? specialInstructions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final MenuItem? menuItem;

  OrderItem({
    required this.id,
    this.orderId,
    this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    double? totalPrice,
    this.imageUrl,
    this.specialInstructions,
    this.createdAt,
    this.updatedAt,
    this.menuItem,
  }) : _totalPriceValue = totalPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

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

    final menuItemJson = json['menu_item'] as Map<String, dynamic>?;
    final MenuItem? menuItem =
        menuItemJson != null ? MenuItem.fromJson(menuItemJson) : null;

    final String name;
    final double price;
    String? imageUrl;
    if (menuItem != null) {
      name = menuItem.name;
      price = menuItem.price;
      imageUrl = menuItem.photoUrl;
    } else {
      final menuItemData = json['menu_item'] as Map<String, dynamic>?;
      if (menuItemData != null) {
        name = menuItemData['nom'] ?? menuItemData['name'] ?? '';
        price = parseDouble(menuItemData['prix'] ??
            menuItemData['price'] ??
            json['prix_unitaire'] ??
            json['price']);
        imageUrl = menuItemData['image'] ??
            menuItemData['image_url'] ??
            menuItemData['imageUrl'] ??
            menuItemData['photo_url'] ??
            menuItemData['photoUrl'];
      } else {
        name = json['name'] ?? json['nom'] ?? '';
        price =
            parseDouble(json['price'] ?? json['prix'] ?? json['prix_unitaire']);
        imageUrl = json['image'] ?? json['image_url'] ?? json['imageUrl'];
      }
    }

    return OrderItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      orderId: json['order_id']?.toString(),
      menuItemId: json['menu_item_id']?.toString(),
      name: name,
      quantity: json['quantity'] ?? json['quantite'] ?? 1,
      price: price,
      totalPrice: parseNullableDouble(
          json['prix_total'] ?? json['total_price'] ?? json['totalPrice']),
      imageUrl: imageUrl,
      specialInstructions: json['instructions_speciales'] ??
          json['special_instructions'] ??
          json['specialInstructions'],
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      menuItem: menuItem,
    );
  }

  double get totalPrice => _totalPriceValue ?? (price * quantity);
}

class DeliveryPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? vehicleType;
  final String? rating;
  final double? latitude;
  final double? longitude;

  DeliveryPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.vehicleType,
    this.rating,
    this.latitude,
    this.longitude,
  });

  String get name {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (firstName.isEmpty) return lastName;
    if (lastName.isEmpty) return firstName;
    return '$firstName $lastName';
  }

  factory DeliveryPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DeliveryPerson(id: '', firstName: '', lastName: '');
    }

    double? latitude;
    double? longitude;
    final currentLocation = json['current_location'] as Map<String, dynamic>?;
    if (currentLocation != null &&
        currentLocation['type'] == 'Point' &&
        currentLocation['coordinates'] != null) {
      final coords = currentLocation['coordinates'] as List;
      if (coords.length >= 2) {
        longitude = (coords[0] as num).toDouble();
        latitude = (coords[1] as num).toDouble();
      }
    }

    latitude ??=
        json['latitude'] != null ? (json['latitude'] as num).toDouble() : null;
    longitude ??= json['longitude'] != null
        ? (json['longitude'] as num).toDouble()
        : null;

    return DeliveryPerson(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: json['first_name'] ??
          json['firstName'] ??
          json['name'] ??
          json['nom'] ??
          '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phoneNumber: json['phone'] ??
          json['phoneNumber'] ??
          json['phone_number'] ??
          json['tel'],
      vehicleType: json['vehicle_type'] ?? json['vehicleType'],
      rating: json['rating']?.toString(),
      latitude: latitude,
      longitude: longitude,
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
  final String? restaurantAddress;
  final String? restaurantImageUrl;
  final DeliveryPerson? deliveryPerson;
  final DateTime? estimatedDeliveryTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? refusalReason;
  final String? delayReason;
  final String? orderType;
  final double? deliveryDistance;
  final int? deliveryTimeMinutes;
  final double? deliveryPrice;
  final ClientModel? client;

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
    this.restaurantAddress,
    this.restaurantImageUrl,
    this.deliveryPerson,
    this.estimatedDeliveryTime,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.refusalReason,
    this.delayReason,
    this.orderType,
    this.deliveryDistance,
    this.deliveryTimeMinutes,
    this.deliveryPrice,
    this.client,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList =
        json['items'] ?? json['orderItems'] ?? json['order_items'] ?? [];
    final List<OrderItem> items = (itemsList as List)
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList();

    DeliveryPerson? deliveryPerson;
    if (json['driver'] != null) {
      deliveryPerson =
          DeliveryPerson.fromJson(json['driver'] as Map<String, dynamic>?);
    } else if (json['deliveryPerson'] != null ||
        json['delivery_person'] != null) {
      deliveryPerson = DeliveryPerson.fromJson(
        (json['deliveryPerson'] ?? json['delivery_person'])
            as Map<String, dynamic>?,
      );
    }

    List<double>? parseGeoJsonPoint(Map<String, dynamic>? location) {
      if (location == null) return null;
      if (location['type'] == 'Point' && location['coordinates'] != null) {
        final coords = location['coordinates'] as List;
        if (coords.length >= 2) {
          return [
            (coords[0] as num).toDouble(),
            (coords[1] as num).toDouble(),
          ];
        }
      }
      return null;
    }

    double? restaurantLat;
    double? restaurantLng;
    Map<String, dynamic>? restaurantJson;
    if (json['restaurant'] != null) {
      restaurantJson = json['restaurant'] is Map
          ? json['restaurant'] as Map<String, dynamic>
          : null;
      if (restaurantJson != null) {
        final location = restaurantJson['location'] as Map<String, dynamic>?;
        final coords = parseGeoJsonPoint(location);
        if (coords != null) {
          restaurantLng = coords[0];
          restaurantLat = coords[1];
        } else {
          restaurantLat = restaurantJson['latitude'] != null
              ? (restaurantJson['latitude'] as num).toDouble()
              : null;
          restaurantLng = restaurantJson['longitude'] != null
              ? (restaurantJson['longitude'] as num).toDouble()
              : null;
        }
      }
    }
    restaurantLat ??= json['restaurantLatitude'] != null
        ? (json['restaurantLatitude'] as num).toDouble()
        : null;
    restaurantLng ??= json['restaurantLongitude'] != null
        ? (json['restaurantLongitude'] as num).toDouble()
        : null;

    double? deliveryLat;
    double? deliveryLng;
    final deliveryLocation =
        json['deliveryLocation'] ?? json['delivery_location'];
    if (deliveryLocation != null) {
      final location = deliveryLocation is Map
          ? deliveryLocation as Map<String, dynamic>
          : null;
      final coords = parseGeoJsonPoint(location);
      if (coords != null) {
        deliveryLng = coords[0];
        deliveryLat = coords[1];
      } else {
        deliveryLat = location?['latitude'] != null
            ? (location!['latitude'] as num).toDouble()
            : null;
        deliveryLng = location?['longitude'] != null
            ? (location!['longitude'] as num).toDouble()
            : null;
      }
    }
    deliveryLat ??= json['deliveryLatitude'] != null
        ? (json['deliveryLatitude'] as num).toDouble()
        : null;
    deliveryLng ??= json['deliveryLongitude'] != null
        ? (json['deliveryLongitude'] as num).toDouble()
        : null;

    String? restaurantName;
    restaurantName = json['restaurantName'] ?? json['restaurant_name'];
    String? restaurantAddress;
    String? restaurantImageUrl;
    if (restaurantJson != null) {
      restaurantName ??= restaurantJson['name'] ?? restaurantJson['nom'];
      restaurantAddress =
          restaurantJson['address'] ?? restaurantJson['adresse'];
      final dynamic cover = restaurantJson['coverImage'] ??
          restaurantJson['cover_image'] ??
          restaurantJson['image'] ??
          restaurantJson['image_url'];
      if (cover is String && cover.isNotEmpty) {
        restaurantImageUrl = cover;
      } else if (restaurantJson['images'] is List &&
          (restaurantJson['images'] as List).isNotEmpty) {
        final first = (restaurantJson['images'] as List).first;
        if (first is String) {
          restaurantImageUrl = first;
        } else if (first is Map<String, dynamic>) {
          restaurantImageUrl = first['url'] as String?;
        }
      }
    }
    restaurantAddress ??=
        json['restaurantAddress'] ?? json['restaurant_address'];
    restaurantImageUrl ??=
        json['restaurantImageUrl'] ?? json['restaurant_image_url'];

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

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    ClientModel? client;
    if (json['client'] != null) {
      client = ClientModel.fromJson(
        json['client'] as Map<String, dynamic>?,
      );
    } else if (json['user'] != null) {
      client = ClientModel.fromJson(
        json['user'] as Map<String, dynamic>?,
      );
    }

    return OrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      orderNumber:
          json['orderNumber'] ?? json['order_number'] ?? json['number'] ?? '',
      status: json['status'] ?? OrderStatus.pending,
      items: items,
      totalPrice: parseDouble(json['totalPrice'] ??
          json['total_price'] ??
          json['total_amount'] ??
          json['total']),
      deliveryAddress: json['deliveryAddress'] ??
          json['delivery_address'] ??
          json['address'],
      restaurantLatitude: restaurantLat,
      restaurantLongitude: restaurantLng,
      deliveryLatitude: deliveryLat,
      deliveryLongitude: deliveryLng,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantImageUrl: restaurantImageUrl,
      deliveryPerson: deliveryPerson,
      estimatedDeliveryTime: parseDate(
          json['estimated_delivery_time'] ?? json['estimated_delivery_time']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      refusalReason: json['refusalReason'] ??
          json['refusal_reason'] ??
          json['decline_reason'],
      delayReason: json['delayReason'] ?? json['delay_reason'],
      orderType: json['order_type'] ?? "delivery",
      deliveryDistance: json['delivery_distance'] != null
          ? parseDouble(json['delivery_distance'])
          : json['delivery_distance'] != null
              ? parseDouble(json['delivery_distance'])
              : null,
      deliveryTimeMinutes: json['deliveryTimeMinutes'] ??
          json['delivery_time_minutes'] ??
          json['delivery_time'],
      deliveryPrice: json['delivery_fee'] != null
          ? parseDouble(json['delivery_fee'])
          : json['delivery_fee'] != null
              ? parseDouble(json['delivery_fee'])
              : null,
      client: client,
    );
  }

  bool get isDelivering => status == OrderStatus.delivering;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isRefused => status == OrderStatus.declined;
  bool get isDelayed => status == OrderStatus.delayed;
}
