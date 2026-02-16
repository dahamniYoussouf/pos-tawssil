import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/restaurant_printer.dart';

class ApiService {
  late Dio _dio;
  late Dio _tokenDio;
  String? _authToken;
  String? _refreshToken;
  String? _cashierId;
  String? _restaurantId;
  Completer<String?>? _refreshCompleter;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _tokenDio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _loadTokensIfNeeded();
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          print('📤 Request: ${options.method} ${options.path}');
          print('📤 Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response: ${response.statusCode} ${response.requestOptions.path}');
          print('✅ Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error: ${error.response?.statusCode} ${error.message}');
          print('❌ Error Data: ${error.response?.data}');
          final shouldRetry = _shouldRefreshToken(error);
          final alreadyRetried = error.requestOptions.extra['retry'] == true;
          final isAuthCall = _isAuthEndpoint(error.requestOptions.path);
          if (shouldRetry && !alreadyRetried && !isAuthCall) {
            final newToken = await _refreshAccessToken();
            if (newToken != null) {
              try {
                final requestOptions = error.requestOptions;
                requestOptions.extra['retry'] = true;
                requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(requestOptions);
                return handler.resolve(response);
              } catch (retryError) {
                return handler.next(
                  retryError is DioException
                      ? retryError
                      : DioException(
                          requestOptions: error.requestOptions,
                          error: retryError,
                        ),
                );
              }
            } else {
              await _clearAuthSession();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadTokensIfNeeded() async {
    // Toujours relire depuis SharedPreferences pour éviter un cache obsolète
    // quand l'utilisateur se déconnecte/reconnecte avec un autre compte.
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') || path.contains('/auth/refresh');
  }

  bool _shouldRefreshToken(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 401) return false;
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['code'] == 'TOKEN_EXPIRED' ||
          data['expired'] == true ||
          (data['message']?.toString().toLowerCase().contains('token') == true);
    }
    if (data is String) {
      return data.toLowerCase().contains('token');
    }
    // Backend may return 401 without explicit token error.
    // If we have a refresh token, attempt a refresh once.
    return true;
  }

  Future<String?> _refreshAccessToken() async {
    await _loadTokensIfNeeded();
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return null;
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      print('🔄 Refreshing access token...');
      final response = await _tokenDio.post('/auth/refresh', data: {
        'refresh_token': _refreshToken,
      });

      final newToken = response.data?['access_token'];
      if (newToken == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

      _authToken = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', newToken);
      print('✅ Access token refreshed');
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearAuthSession() async {
    _authToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  // ========== AUTHENTICATION ==========
  
  Future<void> login(String email, String password) async {
    try {
      print('🔐 Attempting cashier login for: $email');
      
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'type': 'cashier', // ✅ Changé de 'restaurant' à 'cashier'
      });

      print('📥 Full Response: ${response.data}');

      if (response.data['access_token'] == null) {
        final errorMsg = response.data['message'] ?? 'Login failed';
        throw Exception(errorMsg);
      }

      _authToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
      final profile = response.data['profile'];
      
      if (profile == null || profile['id'] == null) {
        throw Exception('Cashier profile information missing from response');
      }
      
      // ✅ Stocker cashier_id et restaurant_id
      _cashierId = profile['id'];
      _restaurantId = profile['restaurant_id']; // Le cashier a un restaurant_id
      
      print('✅ Cashier login successful');
      print('✅ Token: ${_authToken?.substring(0, 20)}...');
      print('✅ Cashier ID: $_cashierId');
      print('✅ Restaurant ID: $_restaurantId');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _authToken!);
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      await prefs.setString('cashier_id', _cashierId!);
      await prefs.setString('restaurant_id', _restaurantId!);
      
      // ✅ Stocker les infos du cashier
      if (profile['first_name'] != null && profile['last_name'] != null) {
        final cashierName = '${profile['first_name']} ${profile['last_name']}';
        await prefs.setString('cashier_name', cashierName);
        print('✅ Cashier Name: $cashierName');
      }
      
      if (profile['cashier_code'] != null) {
        await prefs.setString('cashier_code', profile['cashier_code']);
        print('✅ Cashier Code: ${profile['cashier_code']}');
      }

      // ✅ Stocker le nom du restaurant si disponible
      if (profile['restaurant'] != null && profile['restaurant']['name'] != null) {
        await prefs.setString('restaurant_name', profile['restaurant']['name']);
        print('✅ Restaurant Name: ${profile['restaurant']['name']}');
      }
    } on DioException catch (e) {
      print('❌ Login DioException: ${e.type}');
      print('❌ Status Code: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      print('❌ Message: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        final errorMsg = e.response?.data['message'] ?? 'Email ou mot de passe incorrect';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 403) {
        final errorMsg = e.response?.data['message'] ?? 'Compte désactivé';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data['message'] ?? 'Données invalides';
        throw Exception(errorMsg);
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout: Impossible de se connecter au serveur');
      } else if (e.type == DioExceptionType.unknown && e.error != null) {
        throw Exception('Erreur réseau: Vérifiez votre connexion');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  // ✅ Méthodes pour récupérer les IDs
  Future<String?> getCashierId() async {
    // Toujours relire pour refléter la session courante
    final prefs = await SharedPreferences.getInstance();
    _cashierId = prefs.getString('cashier_id');
    return _cashierId;
  }

  Future<String?> getRestaurantId() async {
    // Toujours relire pour refléter la session courante
    final prefs = await SharedPreferences.getInstance();
    _restaurantId = prefs.getString('restaurant_id');
    return _restaurantId;
  }

  // ========== FOOD CATEGORIES ==========
  
  Future<List<FoodCategory>> fetchFoodCategories() async {
    try {
      print('📥 Fetching food categories...');

      // Priorité: endpoint restaurant avec restaurant_id du caissier
      if (_restaurantId == null) {
        final prefs = await SharedPreferences.getInstance();
        _restaurantId = prefs.getString('restaurant_id');
      }

      Response response;
      try {
        if (_restaurantId != null) {
          response = await _dio.get('/foodcategory/restaurant/$_restaurantId');
        } else {
          response = await _dio.get('/foodcategory/me');
        }
      } on DioException catch (e) {
        // Si 403 sur /me, retente avec /restaurant/{id}
        if (e.response?.statusCode == 403 && _restaurantId != null) {
          response = await _dio.get('/foodcategory/restaurant/$_restaurantId');
        } else {
          rethrow;
        }
      }

      print('📥 Categories Response: ${response.data}');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to fetch categories';
        throw Exception(errorMsg);
      }

      final List<dynamic>? dataList = response.data['data'];
      if (dataList == null) {
        throw Exception('No categories data in response');
      }

      print('✅ Fetched ${dataList.length} categories');

      return dataList.map((json) => FoodCategory.fromJson(json)).toList();
    } on DioException catch (e) {
      print('❌ Category fetch error: ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  // ========== MENU ITEMS ==========
  
  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      print('📥 Fetching menu items...');
      
      // ✅ Le cashier utilise l'endpoint restaurant
      final response = await _dio.get('/menuitem/cashier/menu');
      
      print('📥 Menu Items Response Status: ${response.statusCode}');
      print('📥 Menu Items Response Data: ${response.data}');
      
      if (response.data == null) {
        throw Exception('No response data');
      }
      
      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to fetch menu items';
        throw Exception(errorMsg);
      }

      final List<dynamic>? dataList = response.data['data'];
      if (dataList == null) {
        print('⚠️ No menu items in response, returning empty list');
        return [];
      }
      
      print('✅ Fetched ${dataList.length} menu items');
      
      return dataList.map((json) => MenuItem.fromJson(json)).toList();
    } on DioException catch (e) {
      print('❌ Menu items fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  // ========== ORDERS ==========
  
  Future<Map<String, dynamic>> createOrder(Order order) async {
    try {
      final restaurantId = await getRestaurantId();
      final cashierId = await getCashierId(); // ✅ Récupérer cashier_id
      
      if (restaurantId == null) {
        throw Exception('Restaurant ID not found. Please login again.');
      }
      
      if (cashierId == null) {
        throw Exception('Cashier ID not found. Please login again.');
      }

      print('📤 Creating order as cashier...');
      
      final orderData = {
        ...order.toJson(),
        'id': order.id, // idempotency: keep the same order id across retries
        'restaurant_id': restaurantId,
        'cashier_id': cashierId,
        'created_by_cashier_id': cashierId,
      };
      
      print('📤 Order data: $orderData');

      // ✅ Utiliser l'endpoint POS spécifique aux cashiers
      final response = await _dio.post(
        '/order/create-from-pos',
        data: orderData,
        options: Options(
          headers: {
            'Idempotency-Key': order.id,
          },
        ),
      );

      print('📥 Order Response: ${response.data}');
      
      if (response.data == null) {
        throw Exception('No response data');
      }
      
      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Order creation failed';
        throw Exception(errorMsg);
      }

      final orderData2 = response.data['data'];
      if (orderData2 == null) {
        throw Exception('No order data in response');
      }

      print('✅ Order created: ${orderData2['order_number']}');
      
      return orderData2;
    } on DioException catch (e) {
      print('❌ Order creation error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      
      if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data['message'] ?? 'Données invalides';
        final errors = e.response?.data['errors'];
        if (errors != null) {
          throw Exception('$errorMsg\n${errors.toString()}');
        }
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Endpoint non trouvé. Vérifiez la configuration de l\'API.');
      }
      
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  // Fetch orders history for the cashier (backend-derived)
  Future<List<Order>> fetchOrdersHistory() async {
    try {
      final restaurantId = await getRestaurantId();
      if (restaurantId == null) {
        throw Exception('Restaurant ID not found. Please login again.');
      }

      print('📥 Fetching orders history for restaurant: $restaurantId');
      final response = await _dio.get('/order/cashier/history');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final dataList = response.data['data'] as List<dynamic>?;
      if (dataList == null) {
        throw Exception('No orders data in response');
      }

      print('✅ History fetched: ${dataList.length} orders');
      return dataList.map((json) => Order.fromJson(json)).toList();
    } on DioException catch (e) {
      print('❌ Orders history fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching orders history: $e');
      rethrow;
    }
  }

  // ✅ Méthode pour récupérer le profil du cashier
  Future<Map<String, dynamic>> getCashierProfile() async {
    try {
      print('📥 Fetching cashier profile...');
      
      final response = await _dio.get('/cashier/profile/me');
      
      if (response.data == null) {
        throw Exception('No response data');
      }
      
      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to fetch profile';
        throw Exception(errorMsg);
      }

      final profileData = response.data['data'];
      if (profileData == null) {
        throw Exception('No profile data in response');
      }
      
      print('✅ Cashier profile fetched');
      
      return profileData;
    } on DioException catch (e) {
      print('❌ Profile fetch error: ${e.response?.data ?? e.message}');
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  // ✅ Méthode pour mettre à jour le statut du cashier
  Future<void> updateCashierStatus(String status) async {
    try {
      print('📤 Updating cashier status to: $status');
      
      final response = await _dio.patch('/cashier/status', data: {
        'status': status, // active, on_break, offline
      });
      
      if (response.data == null) {
        throw Exception('No response data');
      }
      
      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to update status';
        throw Exception(errorMsg);
      }
      
      print('✅ Cashier status updated to: $status');
    } on DioException catch (e) {
      print('❌ Status update error: ${e.response?.data ?? e.message}');
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  // ========== DASHBOARD (CASHIER) ==========

  Future<Map<String, dynamic>> fetchCashierDashboardToday() async {
    try {
      final response = await _dio.get('/cashier/dashboard/today');
      if (response.data == null) {
        throw Exception('No response data');
      }
      if (response.data['success'] != true) {
        final msg = response.data['message'] ?? 'Failed to fetch dashboard';
        throw Exception(msg);
      }
      final data = response.data['data'];
      if (data == null) {
        throw Exception('No dashboard data');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      print('❌ Dashboard fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message);
    } catch (e) {
      rethrow;
    }
  }

  // ========== PRINTERS ==========

  /// Récupère la liste des imprimantes du restaurant du cashier
  Future<List<RestaurantPrinter>> fetchRestaurantPrinters() async {
    try {
      final restaurantId = await getRestaurantId();
      if (restaurantId == null) {
        throw Exception('Restaurant ID not found. Please login again.');
      }

      print('📥 Fetching printers for restaurant: $restaurantId');
      
      // Essayer d'abord l'endpoint cashier (si disponible)
      Response response;
      try {
        response = await _dio.get(
          '/cashier/printers',
          queryParameters: {'nocache': 'true'},
        );
      } on DioException catch (e) {
        // Si l'endpoint cashier n'existe pas (404), utiliser l'endpoint admin
        if (e.response?.statusCode == 404) {
          print('⚠️ Cashier endpoint not found, trying admin endpoint...');
          response = await _dio.get('/restaurant/admin/printers/$restaurantId');
        } else {
          rethrow;
        }
      }

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to fetch printers';
        throw Exception(errorMsg);
      }

      final List<dynamic>? dataList = response.data['data'];
      if (dataList == null) {
        print('⚠️ No printers in response, returning empty list');
        return [];
      }

      print('✅ Fetched ${dataList.length} printers');
      return dataList.map((json) => RestaurantPrinter.fromJson(json)).toList();
    } on DioException catch (e) {
      print('❌ Printers fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching printers: $e');
      rethrow;
    }
  }

  /// Crée une nouvelle imprimante (nécessite les droits admin ou restaurant)
  Future<RestaurantPrinter> createPrinter({
    required String restaurantId,
    required String name,
    required String type,
    String connectionType = 'network',
    required String ip,
    required int port,
    String? bluetoothDeviceId,
    String? bluetoothDeviceName,
    int? usbVendorId,
    int? usbProductId,
    String? usbVendorName,
    required bool isEnabled,
    required int paperWidthMm,
  }) async {
    try {
      print('📤 Creating printer: $name (connection: $connectionType)');
      final vid = usbVendorId;
      final pid = usbProductId;
      final vname = usbVendorName;
      final response = await _dio.post('/restaurant/admin/printers', data: {
        'restaurant_id': restaurantId,
        'name': name,
        'type': type,
        'connection_type': connectionType,
        'ip': ip,
        'port': port,
        if (bluetoothDeviceId != null) 'bluetooth_device_id': bluetoothDeviceId,
        if (bluetoothDeviceName != null) 'bluetooth_device_name': bluetoothDeviceName,
        if (vid != null) 'usb_vendor_id': vid,
        if (pid != null) 'usb_product_id': pid,
        if (vname != null) 'usb_vendor_name': vname,
        'is_enabled': isEnabled,
        'paper_width_mm': paperWidthMm,
      });

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to create printer';
        throw Exception(errorMsg);
      }

      final printerData = response.data['data'];
      if (printerData == null) {
        throw Exception('No printer data in response');
      }

      print('✅ Printer created: ${printerData['name']}');
      return RestaurantPrinter.fromJson(printerData);
    } on DioException catch (e) {
      print('❌ Printer creation error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error creating printer: $e');
      rethrow;
    }
  }

  /// Supprime une imprimante
  Future<void> deletePrinter(String printerId) async {
    try {
      print('🗑️ Deleting printer: $printerId');
      
      final response = await _dio.delete('/restaurant/admin/printers/$printerId');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to delete printer';
        throw Exception(errorMsg);
      }

      print('✅ Printer deleted successfully');
    } on DioException catch (e) {
      print('❌ Printer deletion error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Imprimante non trouvée. Elle a peut-être déjà été supprimée.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error deleting printer: $e');
      rethrow;
    }
  }

  /// Met à jour une imprimante existante
  Future<RestaurantPrinter> updatePrinter({
    required String printerId,
    required String name,
    required String type,
    String connectionType = 'network',
    required String ip,
    required int port,
    String? bluetoothDeviceId,
    String? bluetoothDeviceName,
    int? usbVendorId,
    int? usbProductId,
    String? usbVendorName,
    required bool isEnabled,
    required int paperWidthMm,
  }) async {
    try {
      print('📤 Updating printer: $printerId (connection: $connectionType)');
      final vid = usbVendorId;
      final pid = usbProductId;
      final vname = usbVendorName;
      final response = await _dio.put('/restaurant/admin/printers/$printerId', data: {
        'name': name,
        'type': type,
        'connection_type': connectionType,
        'ip': ip,
        'port': port,
        if (bluetoothDeviceId != null) 'bluetooth_device_id': bluetoothDeviceId,
        if (bluetoothDeviceName != null) 'bluetooth_device_name': bluetoothDeviceName,
        if (vid != null) 'usb_vendor_id': vid,
        if (pid != null) 'usb_product_id': pid,
        if (vname != null) 'usb_vendor_name': vname,
        'is_enabled': isEnabled,
        'paper_width_mm': paperWidthMm,
      });

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to update printer';
        throw Exception(errorMsg);
      }

      final printerData = response.data['data'];
      if (printerData == null) {
        throw Exception('No printer data in response');
      }

      print('✅ Printer updated: ${printerData['name']}');
      return RestaurantPrinter.fromJson(printerData);
    } on DioException catch (e) {
      print('❌ Printer update error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error updating printer: $e');
      rethrow;
    }
  }

}

// ========== FOOD CATEGORY MODEL ==========

class FoodCategory {
  final String id;
  final String restaurantId;
  final String nom;
  final String? description;
  final String? iconeUrl;
  final int? ordreAffichage;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodCategory({
    required this.id,
    required this.restaurantId,
    required this.nom,
    this.description,
    this.iconeUrl,
    this.ordreAffichage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      nom: json['nom'],
      description: json['description'],
      iconeUrl: json['icone_url'],
      ordreAffichage: json['ordre_affichage'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
