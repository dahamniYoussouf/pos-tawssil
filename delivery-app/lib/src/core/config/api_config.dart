class ApiConfig {
  static const String baseUrl = "https://wpricoh14061.icosnetcloud.com/api";
  static const String socketUrl = "https://wpricoh14061.icosnetcloud.com";
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get registerUrl => '$baseUrl$registerEndpoint';
}
