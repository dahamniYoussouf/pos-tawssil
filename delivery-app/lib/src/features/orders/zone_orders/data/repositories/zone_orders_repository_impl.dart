import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/orders/zone_orders/data/datasources/zone_orders_remote_data_source.dart';
import 'package:delivery_app/src/features/orders/zone_orders/domain/entities/zone_order_entity.dart';
import 'package:delivery_app/src/features/orders/zone_orders/domain/repositories/zone_orders_repository.dart';

class ZoneOrdersRepositoryImpl implements ZoneOrdersRepository {
  final ZoneOrdersDataSource _dataSource;

  ZoneOrdersRepositoryImpl({
    required ZoneOrdersDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Either<String, List<ZoneOrderEntity>>> getZoneOrders({
    String? query,
  }) async {
    try {
      final zones = await _dataSource.getZoneOrders(query: query);
      return Right<String, List<ZoneOrderEntity>>(zones);
    } catch (_) {
      return const Left<String, List<ZoneOrderEntity>>(
        'Failed to load zone orders',
      );
    }
  }
}
