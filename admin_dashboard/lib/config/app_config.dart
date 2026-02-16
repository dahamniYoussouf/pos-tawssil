class AppConfig {
  // URL de l'API backend
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // URL de base du dashboard admin Next.js (sans le chemin /admin/dashboard)
  static const String adminDashboardBaseUrl = String.fromEnvironment(
    'ADMIN_DASHBOARD_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  
  // URL complète du dashboard admin Next.js
  // Par défaut, utilise localhost:3000/admin/dashboard pour le développement
  // En production, utilisez l'URL de votre déploiement
  static const String adminDashboardUrl = String.fromEnvironment(
    'ADMIN_DASHBOARD_URL',
    defaultValue: 'http://localhost:3000/admin/dashboard',
  );

  // Timeout pour les requêtes réseau
  static const Duration networkTimeout = Duration(seconds: 30);

  // Clés de stockage
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
}
