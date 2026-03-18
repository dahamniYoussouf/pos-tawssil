import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/restaurant_printer.dart';
import '../models/printer_template.dart';

class ApiService {
  late Dio _dio;
  String? _authToken;
  String? _cashierId;
  String? _restaurantId;

  Future<void> _refreshSessionFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _cashierId = prefs.getString('cashier_id');
    _restaurantId = prefs.getString('restaurant_id');
  }

  ApiService() {
    _dio = Dio(BaseOptions(
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
          await _refreshSessionFromPrefs();
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          } else {
            options.headers.remove('Authorization');
          }
          print('📤 Request: ${options.method} ${options.path}');
          print('📤 Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ Response: ${response.statusCode} ${response.requestOptions.path}');
          print('✅ Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Error: ${error.response?.statusCode} ${error.message}');
          print('❌ Error Data: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
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
      if (profile['restaurant'] != null &&
          profile['restaurant']['name'] != null) {
        await prefs.setString('restaurant_name', profile['restaurant']['name']);
        print('✅ Restaurant Name: ${profile['restaurant']['name']}');
      }
    } on DioException catch (e) {
      print('❌ Login DioException: ${e.type}');
      print('❌ Status Code: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      print('❌ Message: ${e.message}');

      if (e.response?.statusCode == 401) {
        final errorMsg =
            e.response?.data['message'] ?? 'Email ou mot de passe incorrect';
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
    await _refreshSessionFromPrefs();
    return _cashierId;
  }

  Future<String?> getRestaurantId() async {
    await _refreshSessionFromPrefs();
    return _restaurantId;
  }

  // ========== FOOD CATEGORIES ==========

  Future<List<FoodCategory>> fetchFoodCategories() async {
    try {
      print('📥 Fetching food categories...');

      // Priorité: endpoint restaurant avec restaurant_id du caissier
      final restaurantId = await getRestaurantId();

      Response response;
      try {
        if (restaurantId != null) {
          response = await _dio.get('/foodcategory/restaurant/$restaurantId');
        } else {
          response = await _dio.get('/foodcategory/me');
        }
      } on DioException catch (e) {
        // Si 403 sur /me, retente avec /restaurant/{id}
        if (e.response?.statusCode == 403 && restaurantId != null) {
          response = await _dio.get('/foodcategory/restaurant/$restaurantId');
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
        final errorMsg =
            response.data['message'] ?? 'Failed to fetch categories';
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
        final errorMsg =
            response.data['message'] ?? 'Failed to fetch menu items';
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
      print(
          '❌ Menu items fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
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
        'restaurant_id': restaurantId,
        'cashier_id': cashierId,
        'created_by_cashier_id': cashierId,
      };

      print('📤 Order data: $orderData');

      // ✅ Utiliser l'endpoint POS spécifique aux cashiers
      final response =
          await _dio.post('/order/create-from-pos', data: orderData);

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
      print(
          '❌ Order creation error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');

      if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data['message'] ?? 'Données invalides';
        final errors = e.response?.data['errors'];
        if (errors != null) {
          throw Exception('$errorMsg\n${errors.toString()}');
        }
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 404) {
        throw Exception(
            'Endpoint non trouvé. Vérifiez la configuration de l\'API.');
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
      print(
          '❌ Orders history fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
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
      print(
          '❌ Dashboard fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
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
        response = await _dio.get('/cashier/printers');
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
      print(
          '❌ Printers fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
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
        if (bluetoothDeviceName != null)
          'bluetooth_device_name': bluetoothDeviceName,
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
      print(
          '❌ Printer creation error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
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

      final response =
          await _dio.delete('/restaurant/admin/printers/$printerId');

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
      print(
          '❌ Printer deletion error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception(
            'Imprimante non trouvée. Elle a peut-être déjà été supprimée.');
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
      final response =
          await _dio.put('/restaurant/admin/printers/$printerId', data: {
        'name': name,
        'type': type,
        'connection_type': connectionType,
        'ip': ip,
        'port': port,
        if (bluetoothDeviceId != null) 'bluetooth_device_id': bluetoothDeviceId,
        if (bluetoothDeviceName != null)
          'bluetooth_device_name': bluetoothDeviceName,
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
      print(
          '❌ Printer update error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error updating printer: $e');
      rethrow;
    }
  }

  /// Imprime une commande via le backend
  /// Le backend gère toutes les méthodes d'impression (réseau, USB, IPP, HTTP, LPD, Serial, mDNS, Bluetooth)
  /// Toutes ces méthodes supportent le backend distant
  Future<void> printOrderViaBackend(String orderId, String printerId) async {
    try {
      print(
          '📤 Sending print request to backend for order $orderId, printer $printerId');

      final response = await _dio
          .post('/restaurant/admin/printers/$printerId/print-order', data: {
        'order_id': orderId,
      });

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        // Extraire les détails d'erreur si disponibles
        final errorData = response.data['error'];
        if (errorData != null && errorData['solutions'] != null) {
          final solutions = (errorData['solutions'] as List<dynamic>)
              .map((s) => s.toString())
              .join('\n');
          final errorMsg =
              '${response.data['message'] ?? 'Failed to print via backend'}\n\n${errorData['detailedMessage'] ?? ''}\n\nSolutions:\n$solutions';
          throw Exception(errorMsg);
        }
        final errorMsg =
            response.data['message'] ?? 'Failed to print via backend';
        throw Exception(errorMsg);
      }

      print('✅ Print request sent successfully to backend');
    } on DioException catch (e) {
      print(
          '❌ Backend print error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }

      // Extraire les détails d'erreur si disponibles
      final errorData = e.response?.data?['error'];
      if (errorData != null && errorData['solutions'] != null) {
        final solutions = (errorData['solutions'] as List<dynamic>)
            .map((s) => s.toString())
            .join('\n');
        final errorMsg =
            '${e.response?.data?['message'] ?? e.message}\n\n${errorData['detailedMessage'] ?? ''}\n\nSolutions:\n$solutions';
        throw Exception(errorMsg);
      }

      throw Exception(
          'Erreur backend: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error printing via backend: $e');
      rethrow;
    }
  }

  /// Ouvre le tiroir-caisse d'une imprimante via le backend
  Future<void> openCashDrawerViaBackend(String printerId) async {
    try {
      print('📤 Sending open drawer request to backend for printer $printerId');

      final response =
          await _dio.post('/restaurant/admin/printers/$printerId/open-drawer');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorData = response.data['error'];
        if (errorData != null && errorData['solutions'] != null) {
          final solutions = (errorData['solutions'] as List<dynamic>)
              .map((s) => s.toString())
              .join('\n');
          final errorMsg =
              '${response.data['message'] ?? 'Failed to open drawer'}\n\n${errorData['detailedMessage'] ?? ''}\n\nSolutions:\n$solutions';
          throw Exception(errorMsg);
        }
        final errorMsg = response.data['message'] ?? 'Failed to open drawer';
        throw Exception(errorMsg);
      }

      print('✅ Cash drawer opened successfully');
    } on DioException catch (e) {
      print(
          '❌ Backend drawer error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }

      final errorData = e.response?.data?['error'];
      if (errorData != null && errorData['solutions'] != null) {
        final solutions = (errorData['solutions'] as List<dynamic>)
            .map((s) => s.toString())
            .join('\n');
        final errorMsg =
            '${e.response?.data?['message'] ?? e.message}\n\n${errorData['detailedMessage'] ?? ''}\n\nSolutions:\n$solutions';
        throw Exception(errorMsg);
      }

      throw Exception(
          'Erreur backend: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error opening drawer via backend: $e');
      rethrow;
    }
  }

  /// Teste une imprimante en envoyant un ticket de test via le backend
  Future<Map<String, dynamic>> testPrinter(String printerId) async {
    try {
      print('🧪 Testing printer: $printerId');

      final response =
          await _dio.post('/restaurant/admin/printers/$printerId/test');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorData = response.data['error'];
        if (errorData != null && errorData['solutions'] != null) {
          final solutions = (errorData['solutions'] as List<dynamic>)
              .map((s) => s.toString())
              .join('\n');
          final errorMsg =
              '${response.data['message'] ?? 'Failed to test printer'}\n\n${errorData['detailedMessage'] ?? ''}\n\nSolutions:\n$solutions';
          throw Exception(errorMsg);
        }
        final errorMsg = response.data['message'] ?? 'Failed to test printer';
        throw Exception(errorMsg);
      }

      print('✅ Printer test completed successfully');
      return {
        'success': true,
        'message':
            response.data['message'] ?? 'Ticket de test envoyé avec succès',
        'printerName': response.data['data']?['printerName'] ?? '',
      };
    } on DioException catch (e) {
      print(
          '❌ Printer test error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }

      final errorData = e.response?.data?['error'];
      if (errorData != null && errorData['solutions'] != null) {
        final solutions = (errorData['solutions'] as List<dynamic>)
            .map((s) => s.toString())
            .join('\n');
        final errorMsg =
            '${e.response?.data?['message'] ?? e.message}\n\n${errorData['detailedMessage'] ?? ''}\n\nSolutions:\n$solutions';
        throw Exception(errorMsg);
      }

      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error testing printer: $e');
      rethrow;
    }
  }

  /// Scanne le réseau pour détecter automatiquement les imprimantes
  Future<Map<String, dynamic>> scanPrinters({
    bool scanNetwork = true,
    String? networkBase,
  }) async {
    try {
      print('🔍 Scanning for printers...');

      final response =
          await _dio.post('/restaurant/admin/printers/scan', data: {
        'scanNetwork': scanNetwork,
        if (networkBase != null) 'networkBase': networkBase,
      });

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to scan printers';
        throw Exception(errorMsg);
      }

      print(
          '✅ Scan completed: ${response.data['data']?['totalFound'] ?? 0} printer(s) found');
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      print(
          '❌ Printer scan error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error scanning printers: $e');
      rethrow;
    }
  }

  /// Récupère les jobs d'impression en attente
  Future<List<Map<String, dynamic>>> getPendingPrintJobs() async {
    try {
      print('📋 Fetching pending print jobs...');

      final response = await _dio.get('/cashier/print-jobs/pending');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg =
            response.data['message'] ?? 'Failed to fetch print jobs';
        throw Exception(errorMsg);
      }

      final jobs = response.data['data'] as List<dynamic>? ?? [];
      print('✅ Found ${jobs.length} pending print job(s)');
      return jobs.map((j) => j as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      print(
          '❌ Print jobs fetch error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching print jobs: $e');
      rethrow;
    }
  }

  /// Réclame un job d'impression (marque comme en cours de traitement)
  Future<Map<String, dynamic>> claimPrintJob(String jobId) async {
    try {
      print('🔒 Claiming print job: $jobId');

      final response = await _dio.post('/cashier/print-jobs/$jobId/claim');

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg =
            response.data['message'] ?? 'Failed to claim print job';
        throw Exception(errorMsg);
      }

      print('✅ Print job claimed successfully');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      print(
          '❌ Claim print job error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error claiming print job: $e');
      rethrow;
    }
  }

  /// Marque un job d'impression comme complété ou échoué
  Future<void> completePrintJob({
    required String jobId,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      print('${success ? '✅' : '❌'} Completing print job: $jobId');

      final response =
          await _dio.post('/cashier/print-jobs/$jobId/complete', data: {
        'success': success,
        if (errorMessage != null) 'error_message': errorMessage,
      });

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool resultSuccess = response.data['success'] == true;
      if (!resultSuccess) {
        final errorMsg =
            response.data['message'] ?? 'Failed to complete print job';
        throw Exception(errorMsg);
      }

      print('✅ Print job marked as ${success ? 'completed' : 'failed'}');
    } on DioException catch (e) {
      print(
          '❌ Complete print job error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error completing print job: $e');
      rethrow;
    }
  }

  /// Teste une imprimante détectée
  Future<Map<String, dynamic>> testDetectedPrinter({
    required String ip,
    int? port,
    required String type,
  }) async {
    try {
      print('🧪 Testing detected printer: $ip ($type)');

      final response =
          await _dio.post('/restaurant/admin/printers/test-detected', data: {
        'ip': ip,
        if (port != null) 'port': port,
        'type': type,
      });

      if (response.data == null) {
        throw Exception('No response data');
      }

      final bool success = response.data['success'] == true;
      if (!success) {
        final errorMsg = response.data['message'] ?? 'Failed to test printer';
        throw Exception(errorMsg);
      }

      print('✅ Printer test completed');
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      print(
          '❌ Printer test error: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('❌ Unexpected error testing printer: $e');
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
