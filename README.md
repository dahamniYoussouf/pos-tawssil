# 🚚 Tawsil Delivery Platform

> A comprehensive multi-app food delivery ecosystem built with Flutter, featuring separate applications for customers, delivery drivers, and restaurant owners.

![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue)
![Framework](https://img.shields.io/badge/Framework-Flutter-02569B)
![State Management](https://img.shields.io/badge/State%20Management-Cubit%2FBloc-blueviolet)
![Languages](https://img.shields.io/badge/Languages-EN%20%7C%20FR%20%7C%20AR-green)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Applications](#-applications)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [State Management](#-state-management-cubitbloc-pattern)
- [Dependency Injection](#-dependency-injection)
- [API Layer](#-api-layer)
- [Authentication](#-authentication-flow)
- [Localization](#-localization)
- [Key Features by App](#-key-features-by-app)
- [Models & Data Layer](#-models--data-layer)
- [Real-time Notifications](#-real-time-notifications)
- [Key Dependencies](#-key-dependencies)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)

---

## 🎯 Overview

**Tawsil** (توصيل - Arabic for "delivery") is a complete food delivery platform consisting of three interconnected Flutter applications. Each app serves a different stakeholder in the delivery ecosystem:

| Role | App | Description |
|------|-----|-------------|
| 👤 **Customers** | `client-app` | Browse restaurants, order food, track deliveries |
| 🚗 **Drivers** | `delivery-app` | Accept deliveries, navigate routes, manage earnings |
| 🍽️ **Restaurants** | `restaurant-app` | Manage menu, process orders, view analytics |

---

## 📱 Applications

### 1. Client App (Customer Application)

The customer-facing mobile application for ordering food from nearby restaurants.

**Key Capabilities:**
- 📍 GPS-based restaurant discovery
- 🔍 Search restaurants by name or category
- 🛒 Shopping cart with customizable options
- 📋 Order placement with delivery/pickup options
- 🗺️ Real-time order tracking with driver location
- ⭐ Review and rate restaurants/orders
- 💾 Save favorite addresses
- 👤 User profile management

**Core Cubits (17+):**
```
AuthCubit          → Authentication & session management
UserCubit          → User profile data
LocationCubit      → GPS & address management
CartCubit          → Shopping cart state
RestaurantCubit    → Restaurant list & details
CategoryCubit      → Food categories
RestaurantSearchCubit → Search functionality
SearchHistoryCubit → Recent searches
HomepageCubit      → Homepage data aggregation
OrderCubit         → Order management
RestaurantDetailsCubit → Single restaurant details
ReviewCubit        → Reviews & ratings
LocaleCubit        → Language switching
AddressSearchCubit → Address autocomplete
MapLocationCubit   → Map interactions
FavoriteAddressCubit → Saved addresses
```

---

### 2. Delivery App (Driver Application)

The driver-facing application for managing food deliveries.

**Key Capabilities:**
- 📬 View available orders nearby
- ✅ Accept or decline delivery requests
- 🗺️ Navigation integration
- 📍 Real-time location tracking
- 🔔 Push notifications for new orders
- 👤 Driver profile management
- 📊 Delivery history

**Core Cubits (4+):**
```
AuthCubit           → Driver authentication
OrdersCubit         → Order management (fetch, accept, decline, refuse)
NotificationsCubit  → WebSocket notifications
DriverCubit         → Driver profile & settings
OrderTrackingMapCubit → Map tracking state
```

---

### 3. Restaurant App (Restaurant Owner Application)

The restaurant management application for handling orders and menu.

**Key Capabilities:**
- 📋 View and manage incoming orders
- ✅ Accept or cancel orders
- 📝 Manage menu items (CRUD)
- 📂 Organize menu categories
- 📊 View sales statistics and analytics
- 🔔 Real-time order notifications
- 👤 Restaurant profile management
- 📜 Order history

**Core Cubits (7+):**
```
AuthCubit           → Restaurant owner authentication
OrdersCubit         → Incoming order management
NotificationsCubit  → Real-time notifications
StatisticsCubit     → Analytics & reporting
CategoryCubit       → Menu categories
RestaurantCubit     → Restaurant profile
MenuItemCubit       → Menu item management
OrderHistoryCubit   → Past orders
```

---

## 🏗️ Architecture

The project follows a **Feature-First Clean Architecture** combined with the **BLoC/Cubit pattern** for state management.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Pages     │  │   Widgets   │  │   Cubits (State Mgmt)   │  │
│  │  (Screens)  │  │ (UI Comps)  │  │  BlocBuilder/Listener   │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│         └────────────────┼──────────────────────┘                │
└──────────────────────────┼───────────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────────┐
│                    DOMAIN LAYER                                   │
│  ┌─────────────┐  ┌──────┴──────┐  ┌─────────────────────────┐   │
│  │  Use Cases  │  │   States    │  │       Repositories      │   │
│  │  (optional) │  │ (Immutable) │  │   (Data Abstraction)    │   │
│  └─────────────┘  └─────────────┘  └───────────┬─────────────┘   │
└────────────────────────────────────────────────┼─────────────────┘
                                                 │
┌────────────────────────────────────────────────┼─────────────────┐
│                      DATA LAYER                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌───────────┴─────────────┐   │
│  │   Models    │  │  Services   │  │     API (Dio/HTTP)      │   │
│  │ (fromJson)  │  │(BaseService)│  │   Real-time (Socket)    │   │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘   │
└───────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Files |
|-------|---------------|-------|
| **Presentation** | UI screens, widgets, user interactions | `pages/`, `widgets/` |
| **State Management** | Business logic, state handling | `cubit/` |
| **Domain** | Use cases, repositories (abstraction) | `usecases/`, `repositories/` |
| **Data** | API calls, data models, services | `services/`, `models/` |

---

## 📁 Project Structure

All three apps follow an identical folder structure for consistency and maintainability:

```
app-name/
├── lib/
│   ├── l10n/                              # 🌍 Localization
│   │   ├── app_ar.arb                     # Arabic translations
│   │   ├── app_en.arb                     # English translations
│   │   ├── app_fr.arb                     # French translations
│   │   └── app_localizations.dart         # Generated localization class
│   │
│   ├── main.dart                          # 🚀 App entry point
│   │
│   └── src/
│       ├── core/                          # 🔧 Shared/Core modules
│       │   ├── config/
│       │   │   └── api_config.dart        # API URLs & endpoints
│       │   ├── extensions/
│       │   │   └── [extension_files].dart # Dart extensions
│       │   ├── localization/
│       │   │   └── locale_cubit.dart      # Language state management
│       │   ├── res/
│       │   │   ├── app_theme.dart         # Theme configuration
│       │   │   ├── color_app.dart         # Color constants
│       │   │   └── media_res.dart         # Asset paths
│       │   ├── services/
│       │   │   ├── base_api_service.dart  # HTTP client wrapper
│       │   │   └── token_storage_service.dart # Secure token storage
│       │   ├── utils/
│       │   │   ├── constant.dart          # App constants
│       │   │   └── dependency_injection.dart # GetIt setup
│       │   └── widgets/
│       │       └── [shared_widgets].dart  # Reusable UI components
│       │
│       └── features/                      # 📦 Feature modules
│           └── [feature_name]/
│               ├── cubit/
│               │   ├── [feature]_cubit.dart    # Cubit logic
│               │   └── [feature]_state.dart    # State definitions
│               ├── models/
│               │   └── [feature]_model.dart    # Data models
│               ├── pages/
│               │   └── [feature]_page.dart     # UI screens
│               ├── repositories/
│               │   └── [feature]_repository.dart # Data abstraction
│               ├── services/
│               │   └── [feature]_service.dart  # API calls
│               ├── usecases/ (optional)
│               │   └── [usecase]_usecase.dart  # Business logic
│               └── widgets/
│                   └── [feature]_widgets.dart  # Feature-specific UI
```

### Features by Application

#### Client App Features

```
features/
├── auth/           # Phone authentication, OTP verification, user profile
├── cart/           # Shopping cart management
├── home/           # Main dashboard with bottom navigation
├── locations/      # GPS location, address management, favorites
├── order/          # Order placement, tracking, history
├── permissions/    # Permission handling (location, notifications)
├── profile/        # User profile settings
├── restaurant/     # Restaurant browsing, search, details
└── review/         # Ratings and reviews
```

#### Delivery App Features

```
features/
├── auth/           # Driver login/signup
├── driver/         # Driver profile and settings
├── home/           # Driver dashboard
├── notifications/  # Real-time order notifications
└── orders/         # Order management (view, accept, decline, refuse)
```

#### Restaurant App Features

```
features/
├── auth/           # Restaurant owner authentication
├── categories/     # Menu category management
├── home/           # Restaurant dashboard
├── menu_items/     # Menu item CRUD operations
├── notifications/  # Real-time order alerts
├── orders/         # Incoming order management
├── restaurant/     # Restaurant profile
└── statistics/     # Sales analytics and reporting
```

---

## 🧠 State Management (Cubit/BLoC Pattern)

The project uses **flutter_bloc** with **Cubit** (a simplified BLoC) for state management and **hydrated_bloc** for state persistence.

### Cubit Structure

```dart
// ═══════════════════════════════════════════════════════════════
// CUBIT FILE: feature_cubit.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter_bloc/flutter_bloc.dart';
import 'feature_state.dart';
import 'feature_repository.dart';

class FeatureCubit extends Cubit<FeatureState> {
  final FeatureRepository _repository;

  FeatureCubit({FeatureRepository? repository})
      : _repository = repository ?? locator<FeatureRepository>(),
        super(FeatureInitial());

  Future<void> loadData() async {
    emit(FeatureLoading());
    
    final result = await _repository.fetchData();
    
    result.fold(
      (error) => emit(FeatureError(message: error)),
      (data) => emit(FeatureLoaded(data: data)),
    );
  }
}
```

### State Structure

```dart
// ═══════════════════════════════════════════════════════════════
// STATE FILE: feature_state.dart
// ═══════════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

abstract class FeatureState extends Equatable {
  const FeatureState();
  
  @override
  List<Object?> get props => [];
}

// Initial state
class FeatureInitial extends FeatureState {}

// Loading state
class FeatureLoading extends FeatureState {}

// Success state with data
class FeatureLoaded extends FeatureState {
  final List<DataModel> data;
  
  const FeatureLoaded({required this.data});
  
  @override
  List<Object?> get props => [data];
}

// Error state
class FeatureError extends FeatureState {
  final String message;
  
  const FeatureError({required this.message});
  
  @override
  List<Object?> get props => [message];
}
```

### Hydrated BLoC (Persistent State)

For states that need to persist across app restarts (like authentication):

```dart
class AuthCubit extends HydratedCubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  // Restore state from storage
  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String;
      switch (type) {
        case 'AuthSuccess':
          return AuthSuccess.fromJson(json);
        default:
          return const AuthInitial();
      }
    } catch (e) {
      return const AuthInitial();
    }
  }

  // Save state to storage
  @override
  Map<String, dynamic>? toJson(AuthState state) {
    return state.toJson();
  }
}
```

### UI Integration

```dart
// ═══════════════════════════════════════════════════════════════
// PAGE FILE: feature_page.dart
// ═══════════════════════════════════════════════════════════════

class FeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureCubit, FeatureState>(
      builder: (context, state) {
        if (state is FeatureLoading) {
          return const CircularProgressIndicator();
        }
        if (state is FeatureLoaded) {
          return ListView.builder(
            itemCount: state.data.length,
            itemBuilder: (context, index) => DataCard(data: state.data[index]),
          );
        }
        if (state is FeatureError) {
          return ErrorWidget(message: state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

---

## 💉 Dependency Injection

The project uses **GetIt** as a service locator for dependency injection.

### Setup (dependency_injection.dart)

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

final locator = GetIt.instance;

void setupLocator() {
  // ═══════════════════════════════════════════════════════════
  // CORE SERVICES
  // ═══════════════════════════════════════════════════════════
  
  // HTTP Client
  locator.registerLazySingleton<Dio>(() => Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 30000),
  ))..interceptors.add(PrettyDioLogger(enabled: kDebugMode)));
  
  // Secure Storage
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  
  // Token Storage
  locator.registerLazySingleton<TokenStorageService>(
    () => TokenStorageService(),
  );

  // ═══════════════════════════════════════════════════════════
  // FEATURE: ORDERS
  // ═══════════════════════════════════════════════════════════
  
  // Service → Repository → Cubit chain
  locator.registerLazySingleton<OrderService>(() => OrderService());
  
  locator.registerLazySingleton<OrderRepository>(
    () => OrderRepository(orderService: locator<OrderService>()),
  );
  
  locator.registerLazySingleton<OrderCubit>(
    () => OrderCubit(orderRepository: locator<OrderRepository>()),
  );

  // ═══════════════════════════════════════════════════════════
  // FEATURE: RESTAURANT
  // ═══════════════════════════════════════════════════════════
  
  locator.registerLazySingleton<RestaurantService>(() => RestaurantService());
  
  locator.registerLazySingleton<RestaurantRepository>(
    () => RestaurantRepository(restaurantService: locator<RestaurantService>()),
  );
  
  locator.registerLazySingleton<RestaurantCubit>(
    () => RestaurantCubit(restaurantRepository: locator<RestaurantRepository>()),
  );
  
  // Factory for per-screen instances
  locator.registerFactory<RestaurantDetailsCubit>(
    () => RestaurantDetailsCubit(repository: locator<RestaurantRepository>()),
  );
}
```

### Registration Types

| Type | Use Case | Example |
|------|----------|---------|
| `registerLazySingleton` | Single instance, created on first access | Services, Repositories |
| `registerSingleton` | Single instance, created immediately | Configuration |
| `registerFactory` | New instance each time | Screen-specific cubits |

---

## 🌐 API Layer

### BaseApiService

All API calls extend `BaseApiService` which provides:

```dart
class BaseApiService {
  late final Dio dio;
  late final TokenStorageService _tokenStorage;

  BaseApiService() {
    dio = locator<Dio>();
    _tokenStorage = locator<TokenStorageService>();
  }

  // ═══════════════════════════════════════════════════════════
  // AUTO-ATTACHED HEADERS
  // ═══════════════════════════════════════════════════════════
  
  Future<Map<String, dynamic>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ═══════════════════════════════════════════════════════════
  // HTTP METHODS
  // ═══════════════════════════════════════════════════════════
  
  Future<Map<String, dynamic>> getRequest(String endpoint, {...});
  Future<Map<String, dynamic>> postRequest(String endpoint, {...});
  Future<Map<String, dynamic>> putRequest(String endpoint, {...});
  Future<Map<String, dynamic>> deleteRequest(String endpoint, {...});

  // ═══════════════════════════════════════════════════════════
  // ERROR HANDLING
  // ═══════════════════════════════════════════════════════════
  
  Map<String, dynamic> _handleError(DioException e) {
    int status;
    if (e.type == DioExceptionType.connectionTimeout) {
      status = -3; // Connection error
    } else if (e.response?.statusCode == 401) {
      status = -1; // Unauthorized
    } else {
      status = -2; // General error
    }
    return {
      'status': status,
      'success': false,
      'message': _getErrorMessage(status, e),
    };
  }
}
```

### API Configuration

```dart
class ApiConfig {
  static const bool useLocal = false;
  
  // Base URLs
  static const String localBaseUrl = 'http://192.168.100.36:3000';
  static const String remoteBaseUrl = 'https://tawssilbackyou.onrender.com';
  
  static String get baseUrl => useLocal ? localBaseUrl : remoteBaseUrl;
  
  // Endpoints
  static const String nearbyRestaurantsEndpoint = '/restaurant/nearbyfilter';
  
  // External APIs
  static const String googlePlacesApiKey = 'YOUR_API_KEY';
}
```

---

## 🔐 Authentication Flow

### Phone Number Authentication (OTP-based)

```
┌─────────────────────────────────────────────────────────────────┐
│                     AUTHENTICATION FLOW                          │
└─────────────────────────────────────────────────────────────────┘

   User                    App                      Server
    │                       │                          │
    │  Enter Phone Number   │                          │
    │──────────────────────>│                          │
    │                       │  POST /auth/send-otp     │
    │                       │─────────────────────────>│
    │                       │                          │
    │                       │  { success, dev_otp }    │
    │                       │<─────────────────────────│
    │                       │                          │
    │   Enter OTP Code      │                          │
    │──────────────────────>│                          │
    │                       │  POST /auth/verify-otp   │
    │                       │─────────────────────────>│
    │                       │                          │
    │                       │  { access_token,         │
    │                       │    refresh_token,        │
    │                       │    profile }             │
    │                       │<─────────────────────────│
    │                       │                          │
    │                       │  Store tokens securely   │
    │                       │  (FlutterSecureStorage)  │
    │                       │                          │
    │   Access Granted!     │                          │
    │<──────────────────────│                          │
```

### Auth States

```dart
// State Flow:
// AuthInitial → AuthLoading → AuthCodeSent → AuthVerificationLoading → AuthSuccess
//                    ↓                              ↓
//               AuthError                      AuthError

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthCodeSent extends AuthState {
  final String phoneNumber;
  final String verificationId;
  final int resendCountdown;
  final bool canResend;
  final bool isNewUser;
}
class AuthVerificationLoading extends AuthState {}
class AuthUpdatingProfile extends AuthState {}
class AuthSuccess extends AuthState {
  final String userId;
  final bool isNewUser;      // Need to complete profile
  final bool needsLocation;  // Need to set delivery address
}
class AuthError extends AuthState {
  final String message;
}
```

### Token Storage

```dart
class TokenStorageService {
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAllTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
```

---

## 🌍 Localization

The platform supports **3 languages**:

| Language | Code | Region |
|----------|------|--------|
| English | `en` | US |
| French | `fr` | FR |
| Arabic | `ar` | DZ (Algeria) |

### ARB File Structure

```json
// app_en.arb
{
  "@@locale": "en",
  "appTitle": "Tawsil",
  "login": "Login",
  "orderNow": "Order Now",
  "deliveryAddress": "Delivery Address",
  "@deliveryAddress": {
    "description": "Label for delivery address input"
  },
  "orderTotal": "Total: {amount} DZD",
  "@orderTotal": {
    "placeholders": {
      "amount": {
        "type": "double",
        "format": "currency"
      }
    }
  }
}
```

### LocaleCubit

```dart
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(LocaleState(locale: const Locale('fr', 'FR')));

  void changeLocale(Locale locale) {
    emit(LocaleState(locale: locale));
  }
}
```

### Usage in App

```dart
MaterialApp(
  locale: localeState.locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en', 'US'),
    Locale('fr', 'FR'),
    Locale('ar', 'DZ'),
  ],
);

// In widgets:
Text(AppLocalizations.of(context)!.orderNow)
```

---

## 📦 Key Features by App

### Client App - Feature Deep Dive

#### 🛒 Cart System

```dart
class CartCubit extends Cubit<CartState> {
  final Map<String, CartItem> _items = {};

  // Add item with options
  void addOrSetItem({
    required MenuModel menuItem,
    required String menuItemId,
    required double price,
    required int quantity,
    String? note,
    List<MenuItemOption>? selectedOptions,
  });

  // Calculate totals
  double get totalPrice => _items.values.fold(
    0.0, (sum, item) => sum + item.totalPrice
  );

  // Per-restaurant filtering
  List<CartItem> getItemsForRestaurant({required String restaurantId});
}
```

#### 🗺️ Location Management

```dart
class LocationCubit extends Cubit<LocationState> {
  // GPS-based location
  Future<void> getGpsLocation();
  
  // Manual address entry
  Future<void> saveManualAddress(String address);
  
  // Saved locations
  Future<void> loadSavedLocation();
  
  // Permission handling
  Future<void> requestLocationPermission();
}
```

#### 📦 Order Tracking

Order statuses flow:
```
pending → accepted → preparing → assigned → delivering → delivered
                                    ↓
                               readyToCollect → collected (pickup orders)
                                    ↓
                                declined / delayed
```

### Delivery App - Feature Deep Dive

#### 📬 Orders Management

```dart
class OrdersCubit extends Cubit<OrdersState> {
  // Fetch available orders
  Future<void> fetchOrders({int page, int limit, String? status});
  
  // Fetch nearby orders (GPS-based)
  Future<void> fetchOrdersNearby();
  
  // Driver actions
  Future<void> assignOrderToDriver(String orderId);
  Future<void> declineOrder(String orderId);
  Future<void> refuseOrder(String orderId, {String? reason});
  
  // Pagination
  Future<void> loadMoreOrders();
}
```

### Restaurant App - Feature Deep Dive

#### 📋 Menu Management

```dart
class MenuItemCubit extends Cubit<MenuItemState> {
  // CRUD operations
  Future<void> createMenuItem(MenuItemModel item);
  Future<void> updateMenuItem(String id, MenuItemModel item);
  Future<void> deleteMenuItem(String id);
  Future<void> toggleAvailability(String id, bool isAvailable);
}
```

#### 📊 Statistics

```dart
class StatisticsCubit extends Cubit<StatisticsState> {
  Future<void> loadDailyStats();
  Future<void> loadWeeklyStats();
  Future<void> loadMonthlyStats();
}
```

---

## 📊 Models & Data Layer

### Example: RestaurantModel

```dart
class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int deliveryMin;
  final int deliveryMax;
  final String? address;
  final double? distance;
  final double? lat;
  final double? lng;
  final bool isPremium;
  final double? deliveryFee;
  final bool isOpen;
  final List<String> categories;
  final List<RestaurantMenuItem> menuItems;
  final List<PromotionModel> promotions;

  // Robust JSON parsing with multiple key name support
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // Handle multiple API schema versions
    final id = (json['id'] ?? json['_id'] ?? json['restaurant_id'] ?? '');
    final name = (json['name'] ?? json['nom'] ?? json['title'] ?? '');
    // ... flexible parsing for backward compatibility
  }

  Map<String, dynamic> toJson() => {...};
}
```

### Example: OrderModel

```dart
class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItem> items;
  final double totalPrice;
  final String? deliveryAddress;
  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? restaurantName;
  final DeliveryPerson? deliveryPerson;
  final DateTime? estimatedDeliveryTime;
  final DateTime? createdAt;
  final String? paymentMethod;
  final String? orderType; // "delivery" or "pickup"

  // Computed properties
  bool get isPending => status == OrderStatus.pending;
  bool get isDelivering => status == OrderStatus.delivering;
  bool get isDelivered => status == OrderStatus.delivered;
}
```

---

## 🔔 Real-time Notifications

The platform uses WebSocket connections for real-time updates.

### NotificationsCubit

```dart
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationService _notificationService;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  // WebSocket connection management
  Future<void> connect();
  Future<void> disconnect();
  Future<void> reconnect();

  // Handle incoming notifications
  void _handleNotification(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    switch (type) {
      case 'new_delivery':
      case 'new_order':
      case 'order_updated':
      case 'order_status_changed':
        emit(NotificationReceived(
          eventType: type,
          data: notification['data'],
        ));
        // Auto-refresh orders list
        break;
    }
  }
}
```

### Notification Types

| Type | App | Action |
|------|-----|--------|
| `new_order` | Restaurant | Show new order alert |
| `order_status_changed` | All | Update order status UI |
| `new_delivery` | Delivery | Show available delivery |
| `driver_alert` | Delivery | Driver-specific alerts |
| `order_cancelled` | All | Remove order from list |

---

## 📚 Key Dependencies

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.0.0          # BLoC/Cubit pattern
  hydrated_bloc: ^9.0.0         # Persistent state
  equatable: ^2.0.0             # Value equality for states

  # Dependency Injection
  get_it: ^7.0.0                # Service locator

  # Networking
  dio: ^5.0.0                   # HTTP client
  pretty_dio_logger: ^1.0.0     # Request/Response logging

  # Storage
  flutter_secure_storage: ^9.0.0 # Secure token storage
  path_provider: ^2.0.0          # File system paths

  # Location
  geolocator: ^10.0.0           # GPS services
  google_maps_flutter: ^2.0.0   # Maps integration

  # UI
  google_fonts: ^6.0.0          # Typography
  
  # Localization
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio / Xcode
- A running backend server

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd tawsil-delivery-platform

# Install dependencies for each app
cd client-app && flutter pub get
cd ../delivery-app && flutter pub get
cd ../restaurant-app && flutter pub get
```

### Running the Apps

```bash
# Client App
cd client-app
flutter run

# Delivery App
cd delivery-app
flutter run

# Restaurant App
cd restaurant-app
flutter run
```

---

## ⚙️ Configuration

### API Configuration

Edit `lib/src/core/config/api_config.dart` in each app:

```dart
class ApiConfig {
  // Toggle between local and remote
  static const bool useLocal = false;
  
  // Local development server
  static const String localBaseUrl = 'http://YOUR_LOCAL_IP:3000';
  
  // Production server
  static const String remoteBaseUrl = 'https://your-production-server.com';
  
  // Google Maps API Key (required for location features)
  static const String googlePlacesApiKey = 'YOUR_GOOGLE_API_KEY';
}
```

### Environment Setup

1. **Google Maps API Key**: Required for location-based features
2. **Backend Server**: Ensure the backend is running and accessible
3. **SMS Service**: Configure SMS provider for OTP (if using real SMS)

---

## 📈 Project Statistics

| Metric | Client App | Delivery App | Restaurant App |
|--------|-----------|--------------|----------------|
| Features | 9 | 5 | 8 |
| Core modules | 7 | 5 | 4 |
| Files in src/ | ~176 | ~45 | ~74 |
| Cubits | 17+ | 5+ | 8+ |
| Supported languages | 3 | 3 | 3 |

---

## 🤝 Contributing

1. Follow the existing architecture patterns
2. Place new features in `src/features/[feature_name]/`
3. Create separate cubit, state, model, service, and repository files
4. Add localization strings to all 3 ARB files
5. Use `locator` for dependency injection

---

## 📄 License

This project is proprietary software. All rights reserved.

---

<p align="center">
  <b>Built with ❤️ using Flutter</b>
</p>
