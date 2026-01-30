class ApiConfig {
  static const bool useLocal = false;

  static const String localBaseUrl = 'http://192.168.100.36:3000';
  static const String localSocketUrl = 'http://192.168.100.36:3000';

  static const String remoteBaseUrl =
      "https://wpricoh14061.icosnetcloud.com/api";
  static const String remoteSocketUrl = "https://wpricoh14061.icosnetcloud.com";
  //  'https://tawssilbackyou.onrender.com';

  // SMS Service API Configuration
  static const String smsBaseUrl = 'https://www.theagencytest.online/api';

  static String get baseUrl => useLocal ? localBaseUrl : remoteBaseUrl;
  static String get socketUrl => useLocal ? localSocketUrl : remoteSocketUrl;

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
      'AIzaSyDffjDg1iLZfXM5jwFhQ2UtLBJAFuTSsHc';
}
