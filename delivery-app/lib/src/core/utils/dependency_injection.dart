import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:delivery_app/src/core/services/token_storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
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
}

