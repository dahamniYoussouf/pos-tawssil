import 'package:delivery_app/src/features/orders/zone_orders/domain/entities/zone_order_entity.dart';
import 'package:equatable/equatable.dart';

abstract class ZoneOrdersState extends Equatable {
  final List<ZoneOrderEntity> zones;
  final String query;

  const ZoneOrdersState({
    this.zones = const [],
    this.query = '',
  });

  @override
  List<Object?> get props => [zones, query];
}

class ZoneOrdersInitial extends ZoneOrdersState {
  const ZoneOrdersInitial();
}

class ZoneOrdersLoading extends ZoneOrdersState {
  const ZoneOrdersLoading({
    super.zones,
    super.query,
  });
}

class ZoneOrdersLoaded extends ZoneOrdersState {
  const ZoneOrdersLoaded({
    required super.zones,
    required super.query,
  });
}

class ZoneOrdersError extends ZoneOrdersState {
  final String message;

  const ZoneOrdersError({
    required this.message,
    super.zones,
    super.query,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}
