import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/orders/zone_orders/domain/entities/zone_order_entity.dart';
import 'package:delivery_app/src/features/orders/zone_orders/domain/repositories/zone_orders_repository.dart';

class GetZoneOrdersUseCase {
  final ZoneOrdersRepository _repository;

  GetZoneOrdersUseCase({
    required ZoneOrdersRepository repository,
  }) : _repository = repository;

  Future<Either<String, List<ZoneOrderEntity>>> call({
    String? query,
  }) {
    return _repository.getZoneOrders(query: query);
  }
}
