// lib/models/restaurant_printer.dart
class RestaurantPrinter {
  final String id;
  final String restaurantId;
  final String name;
  final String type; // 'general' | 'caisse' | 'cuisine' | 'bar'
  final String ip;
  final int port;
  final bool isEnabled;
  final int paperWidthMm; // 58 or 80
  final String? connectionType; // 'network' | 'bluetooth' | 'usb'
  // Bluetooth-specific properties
  final String? bluetoothDeviceId;
  final String? bluetoothDeviceName;
  // USB-specific properties
  final int? usbVendorId;
  final int? usbProductId;
  final String? usbVendorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RestaurantPrinter({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.type,
    required this.ip,
    required this.port,
    required this.isEnabled,
    required this.paperWidthMm,
    this.connectionType,
    this.bluetoothDeviceId,
    this.bluetoothDeviceName,
    this.usbVendorId,
    this.usbProductId,
    this.usbVendorName,
    this.createdAt,
    this.updatedAt,
  });

  // Factory method to create from JSON (alias for fromMap)
  factory RestaurantPrinter.fromJson(Map<String, dynamic> json) {
    return RestaurantPrinter.fromMap(json);
  }

  // Factory method to create from JSON
  factory RestaurantPrinter.fromMap(Map<String, dynamic> map) {
    return RestaurantPrinter(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String? ?? map['restaurantId'] as String? ?? '',
      name: map['name'] as String,
      type: map['type'] as String? ?? 'general',
      ip: map['ip'] as String,
      port: (map['port'] as num?)?.toInt() ?? 9100,
      isEnabled: (map['is_enabled'] as bool?) ?? (map['isEnabled'] as bool?) ?? true,
      paperWidthMm: (map['paper_width_mm'] as num?)?.toInt() ?? (map['paperWidthMm'] as num?)?.toInt() ?? 80,
      connectionType: map['connection_type'] as String? ?? map['connectionType'] as String? ?? 'network',
      bluetoothDeviceId: map['bluetooth_device_id'] as String? ?? map['bluetoothDeviceId'] as String?,
      bluetoothDeviceName: map['bluetooth_device_name'] as String? ?? map['bluetoothDeviceName'] as String?,
      usbVendorId: (map['usb_vendor_id'] as num?)?.toInt() ?? (map['usbVendorId'] as num?)?.toInt(),
      usbProductId: (map['usb_product_id'] as num?)?.toInt() ?? (map['usbProductId'] as num?)?.toInt(),
      usbVendorName: map['usb_vendor_name'] as String? ?? map['usbVendorName'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'type': type,
      'ip': ip,
      'port': port,
      'is_enabled': isEnabled,
      'paper_width_mm': paperWidthMm,
      if (connectionType != null) 'connection_type': connectionType,
      if (bluetoothDeviceId != null) 'bluetooth_device_id': bluetoothDeviceId,
      if (bluetoothDeviceName != null) 'bluetooth_device_name': bluetoothDeviceName,
      if (usbVendorId != null) 'usb_vendor_id': usbVendorId,
      if (usbProductId != null) 'usb_product_id': usbProductId,
      if (usbVendorName != null) 'usb_vendor_name': usbVendorName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Copy with method for immutability
  RestaurantPrinter copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? type,
    String? ip,
    int? port,
    bool? isEnabled,
    int? paperWidthMm,
    String? connectionType,
    String? bluetoothDeviceId,
    String? bluetoothDeviceName,
    int? usbVendorId,
    int? usbProductId,
    String? usbVendorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantPrinter(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      type: type ?? this.type,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isEnabled: isEnabled ?? this.isEnabled,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      connectionType: connectionType ?? this.connectionType,
      bluetoothDeviceId: bluetoothDeviceId ?? this.bluetoothDeviceId,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      usbVendorId: usbVendorId ?? this.usbVendorId,
      usbProductId: usbProductId ?? this.usbProductId,
      usbVendorName: usbVendorName ?? this.usbVendorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RestaurantPrinter(id: $id, name: $name, type: $type, ip: $ip, port: $port)';
  }
}
