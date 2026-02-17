import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/orders/zone_orders/domain/entities/zone_order_entity.dart';

abstract class ZoneOrdersRepository {
  Future<Either<String, List<ZoneOrderEntity>>> getZoneOrders({
    String? query,
  });
}
