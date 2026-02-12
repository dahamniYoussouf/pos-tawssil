class RestaurantPrinter {
  final String id;
  final String name;
  final String type; // general | caisse | cuisine | bar
  final String ip;
  final int port;
  final bool isEnabled;
  final int paperWidthMm; // 58 or 80
  final String connectionType; // network

  const RestaurantPrinter({
    required this.id,
    required this.name,
    required this.type,
    required this.ip,
    required this.port,
    required this.isEnabled,
    required this.paperWidthMm,
    this.connectionType = 'network',
  });

  factory RestaurantPrinter.fromMap(Map<String, dynamic> map) {
    return RestaurantPrinter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      ip: map['ip']?.toString() ?? '',
      port: (map['port'] as num?)?.toInt() ?? 9100,
      isEnabled: (map['isEnabled'] as bool?) ??
          (map['is_enabled'] as bool?) ??
          true,
      paperWidthMm: (map['paperWidthMm'] as num?)?.toInt() ??
          (map['paper_width_mm'] as num?)?.toInt() ??
          80,
      connectionType: map['connectionType']?.toString() ??
          map['connection_type']?.toString() ??
          'network',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'ip': ip,
      'port': port,
      'isEnabled': isEnabled,
      'paperWidthMm': paperWidthMm,
      'connectionType': connectionType,
    };
  }

  RestaurantPrinter copyWith({
    String? id,
    String? name,
    String? type,
    String? ip,
    int? port,
    bool? isEnabled,
    int? paperWidthMm,
    String? connectionType,
  }) {
    return RestaurantPrinter(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isEnabled: isEnabled ?? this.isEnabled,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}
