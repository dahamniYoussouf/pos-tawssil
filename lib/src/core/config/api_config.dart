class ApiConfig {
  static const bool useLocal = false;

  static const String localBaseUrl = 'http://192.168.100.36:3000';

  static const String remoteBaseUrl = 'https://tawssilbackyou.onrender.com';

  // SMS Service API Configuration
  static const String smsBaseUrl = 'https://www.theagencytest.online/api';

  static String get baseUrl => useLocal ? localBaseUrl : remoteBaseUrl;

  static const String restaurantsEndpoint = '/restaurant/getall';
  static const String nearbyRestaurantsEndpoint = '/restaurant/nearbyfilter';
  static const String searchRestaurantsEndpoint = '/restaurant/nearbyfilter';
  static const String nearbyRestaurantsNames = '/restaurant/getnearbynames';

  static String get restaurantsUrl => '$baseUrl$restaurantsEndpoint';
  static String get nearbyRestaurantsUrl => '$baseUrl$nearbyRestaurantsEndpoint';
  static String get searchRestaurantsUrl => '$baseUrl$searchRestaurantsEndpoint';

  // storage key
  static const String storageKeyToken = 'access_token';
}
