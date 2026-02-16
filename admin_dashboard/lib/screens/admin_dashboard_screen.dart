import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// Import web interop pour l'iframe sur le web - uniquement sur le web
// Ces imports ne seront disponibles que sur le web où dart:html existe
import '../widgets/html_stub.dart' if (dart.library.html) 'dart:html' as html;
import '../widgets/platform_view_registry_stub.dart' if (dart.library.html) 'dart:ui_web' as ui_web;

// Import conditionnel: WebView pour mobile seulement
import 'package:webview_flutter/webview_flutter.dart' if (dart.library.html) '../widgets/webview_stub.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart' if (dart.library.html) '../widgets/webview_stub.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  dynamic _controller; // WebViewController pour mobile seulement
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  int _loadingProgress = 0;
  Timer? _reconnectionTimer;
  String? _iframeViewType; // Type de vue pour l'iframe sur le web

  @override
  void initState() {
    super.initState();
    _setupNotificationService();
    
    if (kIsWeb) {
      // Pour le web: initialiser l'iframe
      _initializeWebFrame();
      _injectTokensToLocalStorage();
    } else {
      // Pour mobile: initialiser WebView
      _initializeWebView();
    }
  }

  @override
  void dispose() {
    _notificationService.disconnectWebSocket();
    _reconnectionTimer?.cancel();
    super.dispose();
  }

  // Initialiser l'iframe pour le web
  void _initializeWebFrame() {
    if (!kIsWeb) return;
    
    final dashboardUrl = AppConfig.adminDashboardUrl;
    _iframeViewType = 'dashboard-iframe-${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // Créer l'iframe HTML - uniquement sur le web
      final iframe = html.IFrameElement()
        ..src = dashboardUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      
      iframe.onLoad.listen((_) {
        print('✅ Dashboard iframe loaded');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // Injecter les tokens après le chargement
        _injectTokensToIframe(iframe);
      });
      
      // Enregistrer la factory de vue (doit être fait avant build)
      ui_web.platformViewRegistry.registerViewFactory(
        _iframeViewType!,
        (int viewId) => iframe,
      );
      
      setState(() {
        _isLoading = true;
      });
    } catch (e) {
      print('❌ Error initializing iframe: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Injecter les tokens dans le localStorage
  Future<void> _injectTokensToLocalStorage() async {
    await _authService.init();
    if (_authService.isAuthenticated && kIsWeb) {
      try {
        // Injecter les tokens via JavaScript dans la page
        // Note: Cette approche nécessite que le dashboard soit dans le même domaine
        // Pour un domaine différent, le dashboard doit gérer l'authentification via API
      } catch (e) {
        print('❌ Error in token injection: $e');
      }
    }
  }

  // Initialiser le WebView pour mobile
  void _initializeWebView() {
    try {
      // Ignorer pour le web
      if (kIsWeb) return;
      
      final platform = WebViewPlatform.instance;
      late final PlatformWebViewControllerCreationParams params;

      if (platform is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _loadingProgress = 0;
              });
            },
            onProgress: (int progress) {
              setState(() {
                _loadingProgress = progress;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
              _injectTokens();
            },
            onWebResourceError: (WebResourceError error) {
              print('❌ WebView error: ${error.description}');
              if (error.description.contains('net::ERR_CONNECTION_REFUSED') ||
                  error.description.contains('Network error')) {
                _showErrorDialog('Impossible de se connecter au dashboard. Vérifiez que le serveur est démarré.');
              }
            },
          ),
        );

      final dashboardUrl = AppConfig.adminDashboardUrl;
      print('🌐 Loading dashboard: $dashboardUrl');
      controller.loadRequest(Uri.parse(dashboardUrl));

      _controller = controller;
    } catch (e) {
      print('❌ Error initializing WebView: $e');
      if (!kIsWeb) {
        _showErrorDialog('Erreur lors de l\'initialisation du WebView: $e');
      }
    }
  }

  // Configurer le service de notifications
  void _setupNotificationService() async {
    await _notificationService.init();
    if (!kIsWeb) {
      await _notificationService.createNotificationChannel();
    }

    _notificationService.onNotificationReceived = (notification) {
      // Optionnel: naviguer vers la page des notifications
    };

    await _notificationService.registerDeviceTokenIfPossible();
    await _notificationService.connectWebSocket();

    _reconnectionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_notificationService.isSocketConnected) {
        print('🔄 Attempting to reconnect WebSocket...');
        _notificationService.connectWebSocket();
      }
    });
  }

  // Injecter les tokens dans le WebView (mobile uniquement)
  Future<void> _injectTokens() async {
    if (kIsWeb) return;
    
    await _authService.init();
    final injectionScript = _authService.getLocalStorageInjectionScript();
    if (injectionScript.isNotEmpty && _controller != null) {
      try {
        await (_controller as WebViewController).runJavaScript(injectionScript);
        print('✅ Tokens injected into WebView');
      } catch (e) {
        print('❌ Error injecting tokens: $e');
      }
    }
  }

  // Afficher une boîte de dialogue d'erreur
  void _showErrorDialog(String message) {
    if (!mounted) return;
    // Defer dialog to the next frame to avoid using inherited widgets during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (!kIsWeb && _controller != null) {
                  (_controller as WebViewController).reload();
                }
              },
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  // Recharger la vue
  Future<void> _reloadView() async {
    if (kIsWeb) {
      // Recharger l'iframe sur le web
      setState(() {
        _isLoading = true;
      });
      await _injectTokensToLocalStorage();
      setState(() {
        _isLoading = false;
      });
    } else if (_controller != null) {
      await _injectTokens();
      (_controller as WebViewController).reload();
    }
  }

  // Ouvrir les notifications
  Future<void> _openNotifications() async {
    final url = Uri.parse('${AppConfig.adminDashboardBaseUrl}/admin/notifications');
    if (kIsWeb) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } else if (_controller != null) {
      (_controller as WebViewController).runJavaScript(
        "window.location.href = '$url';",
      );
    }
  }

  // Construire le widget iframe pour le web
  Widget _buildWebFrame() {
    if (!kIsWeb || _iframeViewType == null) {
      return const SizedBox.shrink();
    }
    
    // Utiliser HtmlElementView avec le viewType enregistré
    return HtmlElementView(
      viewType: _iframeViewType!,
    );
  }
  
  // Injecter les tokens dans l'iframe (web)
  Future<void> _injectTokensToIframe(dynamic iframe) async {
    if (!kIsWeb || !_authService.isAuthenticated) return;
    
    try {
      await _authService.init();
      final token = _authService.token;
      final refreshToken = _authService.refreshToken;
      final userJson = _authService.user != null 
          ? _authService.user.toString().replaceAll("'", "\\'")
          : 'null';

      // Injecter dans l'iframe via postMessage ou en accédant au contenu
      // Note: Les iframes cross-origin limitent l'accès au contenu
      // On peut utiliser postMessage si le dashboard l'écoute
      try {
        if (iframe.contentWindow != null) {
          // Essayer d'injecter via postMessage
          iframe.contentWindow.postMessage(
            {
              'type': 'SET_TOKENS',
              'access_token': token,
              'refresh_token': refreshToken,
              'user': userJson,
            },
            '*',
          );
        }
      } catch (e) {
        // Ignorer si postMessage n'est pas disponible
        print('⚠️ Could not inject tokens via postMessage: $e');
      }
    } catch (e) {
      print('❌ Error injecting tokens to iframe: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Mode web: afficher l'iframe intégré
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tawsil Admin Dashboard'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recharger',
              onPressed: _reloadView,
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notifications',
              onPressed: _openNotifications,
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildWebFrame(),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      );
    }

    // Mode mobile: utiliser WebView
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawsil Admin Dashboard'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger',
            onPressed: _reloadView,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: _openNotifications,
          ),
        ],
      ),
      body: _controller != null
          ? Stack(
              children: [
                WebViewWidget(controller: _controller as WebViewController),
                if (_isLoading)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _loadingProgress / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
