import 'package:delivery_app/src/features/orders/zone_orders/data/models/zone_order_model.dart';

abstract class ZoneOrdersDataSource {
  Future<List<ZoneOrderModel>> getZoneOrders({String? query});
}

class ZoneOrdersFakeDataSource implements ZoneOrdersDataSource {
  @override
  Future<List<ZoneOrderModel>> getZoneOrders({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final normalizedQuery = (query ?? '').trim().toLowerCase();
    final zones = _fakeZones
        .map((zone) => ZoneOrderModel.fromJson(zone))
        .where((zone) =>
            normalizedQuery.isEmpty ||
            zone.name.toLowerCase().contains(normalizedQuery))
        .toList();
    return zones;
  }
}

const List<Map<String, dynamic>> _fakeZones = [
  {
    'id': 'zone_1',
    'name': 'Dar El Beida',
    'availableOrders': 12,
    'estimatedMinutes': 8,
    'progress': 0.72,
    'loadLevel': 'high',
  },
  {
    'id': 'zone_2',
    'name': 'Bab Ezzouar',
    'availableOrders': 8,
    'estimatedMinutes': 5,
    'progress': 0.56,
    'loadLevel': 'medium',
  },
  {
    'id': 'zone_3',
    'name': 'Cheraga',
    'availableOrders': 15,
    'estimatedMinutes': 22,
    'progress': 0.9,
    'loadLevel': 'high',
  },
  {
    'id': 'zone_4',
    'name': 'Hydra',
    'availableOrders': 5,
    'estimatedMinutes': 10,
    'progress': 0.45,
    'loadLevel': 'low',
  },
  {
    'id': 'zone_5',
    'name': 'Kouba',
    'availableOrders': 9,
    'estimatedMinutes': 12,
    'progress': 0.61,
    'loadLevel': 'medium',
  },
];
