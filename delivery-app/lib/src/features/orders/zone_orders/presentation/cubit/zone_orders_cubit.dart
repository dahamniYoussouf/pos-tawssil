import 'package:delivery_app/src/features/orders/zone_orders/domain/usecases/get_zone_orders_usecase.dart';
import 'package:delivery_app/src/features/orders/zone_orders/presentation/cubit/zone_orders_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZoneOrdersCubit extends Cubit<ZoneOrdersState> {
  final GetZoneOrdersUseCase _getZoneOrdersUseCase;

  ZoneOrdersCubit({
    required GetZoneOrdersUseCase getZoneOrdersUseCase,
  })  : _getZoneOrdersUseCase = getZoneOrdersUseCase,
        super(const ZoneOrdersInitial());

  Future<void> loadZones({String? query}) async {
    final currentQuery = query ?? state.query;
    emit(ZoneOrdersLoading(zones: state.zones, query: currentQuery));

    final result = await _getZoneOrdersUseCase.call(query: currentQuery);
    result.fold(
      (error) => emit(
        ZoneOrdersError(
          message: error,
          zones: state.zones,
          query: currentQuery,
        ),
      ),
      (zones) => emit(
        ZoneOrdersLoaded(
          zones: zones,
          query: currentQuery,
        ),
      ),
    );
  }
}
