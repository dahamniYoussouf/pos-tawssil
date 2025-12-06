import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  late Dio _dio;
  String? _authToken;
  String? _cashierId;  // ✅ Changé de _restaurantId
  String? _restaurantId; // ✅ Ajouté pour le restaurant du cashier

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
          if (_authToken == null) {
            final prefs = await SharedPreferences.getInstance();
            _authToken = prefs.getString('auth_token');
          }
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
    if (_cashierId == null) {
      final prefs = await SharedPreferences.getInstance();
      _cashierId = prefs.getString('cashier_id');
    }
    return _cashierId;
  }

  Future<String?> getRestaurantId() async {
    if (_restaurantId == null) {
      final prefs = await SharedPreferences.getInstance();
      _restaurantId = prefs.getString('restaurant_id');
    }
    return _restaurantId;
  }

  // ========== FOOD CATEGORIES ==========
  
  Future<List<FoodCategory>> fetchFoodCategories() async {
    try {
      print('📥 Fetching food categories...');
      
      // ✅ Le cashier utilise l'endpoint restaurant car il appartient à un restaurant
      final response = await _dio.get('/foodcategory/me');
      
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
        'restaurant_id': restaurantId,
        'cashier_id': cashierId, // ✅ Inclure cashier_id
        'order_type': 'pickup',
        'payment_method': order.paymentMethod,
        'items': order.items.map((item) => {
          'menu_item_id': item.menuItemId,
          'quantity': item.quantite,
          'special_instructions': item.instructionsSpeciales ?? "",
        }).toList(),
      };
      
      print('📤 Order data: $orderData');

      // ✅ Utiliser l'endpoint POS spécifique aux cashiers
      final response = await _dio.post('/order/create-from-pos', data: orderData);

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