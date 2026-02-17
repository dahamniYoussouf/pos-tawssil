import 'package:delivery_app/src/core/services/base_api_service.dart';
import 'package:delivery_app/src/features/orders/zone_orders/data/models/zone_order_model.dart';

abstract class ZoneOrdersDataSource {
  Future<List<ZoneOrderModel>> getZoneOrders({String? query});
}

class ZoneOrdersRemoteDataSource extends BaseApiService
    implements ZoneOrdersDataSource {
  static const int _nearbyRadiusMeters = 5000;
  static const int _nearbyLimit = 12;

  @override
  Future<List<ZoneOrderModel>> getZoneOrders({String? query}) async {
    final normalizedQuery = (query ?? '').trim().toLowerCase();

    final response = await getRequest(
      '/driver/zones/nearby',
      queryParameters: const <String, dynamic>{
        'radius': _nearbyRadiusMeters,
        'limit': _nearbyLimit,
      },
    );

    final rawZones = _extractZonesList(response);
    return rawZones
        .map(_toZoneOrderJson)
        .map(ZoneOrderModel.fromJson)
        .where((zone) =>
            normalizedQuery.isEmpty ||
            zone.name.toLowerCase().contains(normalizedQuery))
        .toList();
  }
}

List<Map<String, dynamic>> _extractZonesList(Map<String, dynamic> response) {
  final candidates = <dynamic>[
    response['data'],
    response['zones'],
    response['results'],
    response['items'],
    response,
  ];

  for (final candidate in candidates) {
    final zones = _asZoneList(candidate);
    if (zones.isNotEmpty) {
      return zones;
    }
  }

  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _asZoneList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.map(
              (key, val) => MapEntry(key.toString(), val),
            ))
        .toList();
  }

  if (value is Map<String, dynamic>) {
    final nested = <dynamic>[
      value['zones'],
      value['items'],
      value['results'],
      value['list'],
    ];
    for (final item in nested) {
      final zones = _asZoneList(item);
      if (zones.isNotEmpty) {
        return zones;
      }
    }
  }

  return const <Map<String, dynamic>>[];
}

Map<String, dynamic> _toZoneOrderJson(Map<String, dynamic> zone) {
  final availableOrders = _asInt(
    zone['availableOrders'] ??
        zone['available_orders'] ??
        zone['ordersCount'] ??
        zone['orders_count'] ??
        zone['pendingOrders'] ??
        zone['pending_orders'],
  );

  final estimatedMinutes = _asInt(
    zone['estimatedMinutes'] ??
        zone['estimated_minutes'] ??
        zone['etaMinutes'] ??
        zone['eta_minutes'] ??
        zone['eta'],
  );

  return <String, dynamic>{
    'id': (zone['id'] ?? zone['_id'] ?? '').toString(),
    'name': (zone['name'] ??
            zone['zoneName'] ??
            zone['zone_name'] ??
            zone['label'] ??
            'Unknown Zone')
        .toString(),
    'availableOrders': availableOrders,
    'estimatedMinutes': estimatedMinutes,
    'progress': _resolveProgress(zone, availableOrders),
    'loadLevel': _resolveLoadLevel(zone, availableOrders),
  };
}

double _resolveProgress(Map<String, dynamic> zone, int availableOrders) {
  final rawProgress = zone['progress'] ?? zone['completion'] ?? zone['load'];
  if (rawProgress == null) {
    return (availableOrders / 20).clamp(0.0, 1.0);
  }

  final value = _asDouble(rawProgress);
  if (value > 1) {
    return (value / 100).clamp(0.0, 1.0);
  }
  return value.clamp(0.0, 1.0);
}

String _resolveLoadLevel(Map<String, dynamic> zone, int availableOrders) {
  final raw = zone['loadLevel'] ?? zone['load_level'] ?? zone['load'];
  final normalized = raw?.toString().toLowerCase();
  if (normalized == 'low' || normalized == 'medium' || normalized == 'high') {
    return normalized!;
  }

  if (availableOrders >= 12) {
    return 'high';
  }
  if (availableOrders >= 6) {
    return 'medium';
  }
  return 'low';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
