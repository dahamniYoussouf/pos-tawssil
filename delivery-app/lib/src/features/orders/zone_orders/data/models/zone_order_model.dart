import 'package:delivery_app/src/features/orders/zone_orders/domain/entities/zone_order_entity.dart';

class ZoneOrderModel extends ZoneOrderEntity {
  const ZoneOrderModel({
    required super.id,
    required super.name,
    required super.availableOrders,
    required super.estimatedMinutes,
    required super.progress,
    required super.loadLevel,
  });

  factory ZoneOrderModel.fromJson(Map<String, dynamic> json) {
    final load = (json['loadLevel'] ?? '').toString().toLowerCase();
    return ZoneOrderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      availableOrders: json['availableOrders'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      progress: (json['progress'] as num).toDouble(),
      loadLevel: _parseLoadLevel(load),
    );
  }

  static ZoneLoadLevel _parseLoadLevel(String value) {
    switch (value) {
      case 'high':
        return ZoneLoadLevel.high;
      case 'low':
        return ZoneLoadLevel.low;
      default:
        return ZoneLoadLevel.medium;
    }
  }
}
