import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/order/index.dart';
import 'package:client_app/src/features/order/widgets/cubit/order_tracking_map_cubit.dart';
import 'package:client_app/src/features/review/index.dart';
import 'package:client_app/src/features/restaurant/cubit/category_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_search_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_details_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/search_history_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_cubit.dart';
import 'package:client_app/src/features/restaurant/services/restaurant_service.dart';
import 'package:client_app/src/features/restaurant/repositories/restaurant_repository.dart';
import 'package:client_app/src/features/restaurant/repositories/homepage_repository.dart';
import 'package:client_app/src/core/notifications/cubit/notifications_cubit.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:client_app/src/core/localization/locale_cubit.dart';
import 'package:client_app/src/core/utils/constant.dart';
import 'package:client_app/src/core/services/token_storage_service.dart';
import 'package:client_app/src/core/services/notification_service.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final locator = GetIt.instance;

void setupLocator() {
  final options = BaseOptions(
    connectTimeout: const Duration(milliseconds: dioConnectTimeout),
    receiveTimeout: const Duration(milliseconds: dioReceiveTimeout),
    sendTimeout: const Duration(milliseconds: dioSendTimeout),
  );

  // Core services
  locator.registerLazySingleton<LocaleCubit>(() => LocaleCubit());
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
  locator.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  locator.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(
      notificationService: locator<NotificationService>(),
    ),
  );
  locator.registerLazySingleton<OrderService>(() => OrderService());

  locator.registerLazySingleton<OrderCubit>(
      () => OrderCubit(orderService: locator<OrderService>()));

  // Cart services
  locator.registerLazySingleton<CartCubit>(() => CartCubit());

  locator.registerLazySingleton<OrderTrackingMapCubit>(
      () => OrderTrackingMapCubit());

  // Restaurant services
  locator.registerLazySingleton<RestaurantService>(() => RestaurantService());

  locator.registerLazySingleton<RestaurantRepository>(
    () => RestaurantRepository(restaurantService: locator<RestaurantService>()),
  );

  locator.registerLazySingleton<UserCubit>(() => UserCubit());

  locator.registerLazySingleton<RestaurantCubit>(() =>
      RestaurantCubit(restaurantRepository: locator<RestaurantRepository>()));

  locator.registerLazySingleton<CategoryCubit>(() =>
      CategoryCubit(restaurantRepository: locator<RestaurantRepository>()));

  locator.registerLazySingleton<HomepageRepository>(
    () => HomepageRepository(),
  );

  locator.registerLazySingleton<HomepageCubit>(
      () => HomepageCubit(homepageRepository: locator<HomepageRepository>()));

  locator.registerLazySingleton<RestaurantSearchCubit>(() =>
      RestaurantSearchCubit(
          restaurantRepository: locator<RestaurantRepository>()));
  locator.registerFactory<RestaurantDetailsCubit>(() =>
      RestaurantDetailsCubit(repository: locator<RestaurantRepository>()));
  locator.registerLazySingleton<SearchHistoryCubit>(() => SearchHistoryCubit());
  locator.registerLazySingleton<LocationCubit>(() => LocationCubit());

  // Review services
  locator.registerLazySingleton<ReviewService>(() => ReviewService());
  locator.registerFactory<ReviewCubit>(
    () => ReviewCubit(reviewService: locator<ReviewService>()),
  );
}
