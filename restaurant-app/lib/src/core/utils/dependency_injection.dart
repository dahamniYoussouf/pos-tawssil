import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:restaurant_app/src/core/services/token_storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:restaurant_app/src/features/auth/services/location_geocoding_service.dart';
import 'package:restaurant_app/src/features/orders/repositories/order_repository.dart';
import 'package:restaurant_app/src/features/orders/repositories/order_history_repository.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_cubit.dart';
import 'package:restaurant_app/src/features/notifications/services/notification_service.dart';
import 'package:restaurant_app/src/features/statistics/repositories/statistics_repository.dart';
import 'package:restaurant_app/src/features/categories/services/category_service.dart';
import 'package:restaurant_app/src/features/categories/repositories/category_repository.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/services/restaurant_service.dart';
import 'package:restaurant_app/src/features/restaurant/repositories/restaurant_repository.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/category_selection_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/services/menu_item_service.dart';
import 'package:restaurant_app/src/features/menu_items/repositories/menu_item_repository.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'constant.dart';

final locator = GetIt.instance;

void setupLocator() {
  final options = BaseOptions(
    connectTimeout: const Duration(milliseconds: dioConnectTimeout),
    receiveTimeout: const Duration(milliseconds: dioReceiveTimeout),
    sendTimeout: const Duration(milliseconds: dioSendTimeout),
  );

  locator.registerLazySingleton<Dio>(() => Dio(options)
    ..interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      request: true,
      error: true,
      compact: false,
      enabled: kDebugMode,
    )));
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  locator.registerLazySingleton<TokenStorageService>(
    () => TokenStorageService(),
  );
  locator.registerLazySingleton<LocationGeocodingService>(
    () => const LocationGeocodingService(),
  );
  locator.registerLazySingleton<OrderRepository>(
    () => OrderRepository(),
  );
  locator.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  locator.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepository(),
  );
  locator.registerLazySingleton<CategoryService>(
    () => CategoryService(),
  );
  locator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepository(categoryService: locator<CategoryService>()),
  );
  locator.registerLazySingleton<CategoryCubit>(
    () => CategoryCubit(categoryRepository: locator<CategoryRepository>()),
  );
  locator.registerLazySingleton<RestaurantService>(
    () => RestaurantService(),
  );
  locator.registerLazySingleton<RestaurantRepository>(
    () => RestaurantRepository(restaurantService: locator<RestaurantService>()),
  );
  locator.registerLazySingleton<RestaurantCubit>(
    () =>
        RestaurantCubit(restaurantRepository: locator<RestaurantRepository>()),
  );
  locator.registerLazySingleton<MenuItemService>(
    () => MenuItemService(),
  );
  locator.registerLazySingleton<MenuItemRepository>(
    () => MenuItemRepository(menuItemService: locator<MenuItemService>()),
  );
  locator.registerFactory<MenuItemCubit>(
    () => MenuItemCubit(menuItemRepository: locator<MenuItemRepository>()),
  );
  locator.registerLazySingleton<CategorySelectionCubit>(
    () => CategorySelectionCubit(),
  );
  locator.registerLazySingleton<OrderHistoryRepository>(
    () => OrderHistoryRepository(),
  );
  locator.registerFactory<OrderHistoryCubit>(
    () => OrderHistoryCubit(repository: locator<OrderHistoryRepository>()),
  );
}
