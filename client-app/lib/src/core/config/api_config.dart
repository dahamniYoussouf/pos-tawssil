class ApiConfig {
  static const bool useLocal = false;

  static const String localBaseUrl = 'http://192.168.100.36:3000';

  static const String remoteBaseUrl = 'https://tawssilbackyou.onrender.com';

  // SMS Service API Configuration
  static const String smsBaseUrl = 'https://www.theagencytest.online/api';

  static String get baseUrl => useLocal ? localBaseUrl : remoteBaseUrl;

  static const String nearbyRestaurantsEndpoint = '/restaurant/nearbyfilter';
  static const String nearbyRestaurantsNames = '/restaurant/getnearbynames';

  static String get nearbyRestaurantsUrl =>
      '$baseUrl$nearbyRestaurantsEndpoint';

  // storage key
  static const String storageKeyToken = 'access_token';

  // Google Places API Key
  // Note: Replace with your actual API key or load from environment/config
  // For production, consider loading from secure storage or environment variables
  static const String googlePlacesApiKey =
      'AIzaSyCJXJUAkRyVdR_mndA6yy7gTSXrFvpt2Wg';
}
