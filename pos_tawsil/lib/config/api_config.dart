class ApiConfig {
  // Backend API URL
  static const String baseUrl = 'https://tawsilapp.com/api/';

  static const String restaurantPrefix = '';
  
  static const String menuItemsEndpoint = '$restaurantPrefix/menu-items';
  static const String categoriesEndpoint = '$restaurantPrefix/food-categories';
  static const String ordersEndpoint = '$restaurantPrefix/orders';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
