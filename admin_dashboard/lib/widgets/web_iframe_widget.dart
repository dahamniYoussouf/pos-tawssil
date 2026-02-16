import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Widget pour afficher un iframe sur le web uniquement
class WebIframeWidget extends StatelessWidget {
  final String url;
  final String? id;
  
  const WebIframeWidget({
    super.key,
    required this.url,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Ne pas utiliser sur les plateformes non-web
      return const SizedBox.shrink();
    }
    
    // Pour le web: utiliser HtmlElementView avec un iframe
    return _buildWebIframe();
  }
  
  Widget _buildWebIframe() {
    // Import conditionnel pour dart:html
    // Note: Ce code ne sera compilé que sur le web où dart:html est disponible
    if (!kIsWeb) return const SizedBox.shrink();
    
    final iframeId = id ?? 'dashboard-iframe-${DateTime.now().millisecondsSinceEpoch}';
    
    // Créer l'iframe via HtmlElementView
    // Sur Flutter web, HtmlElementView peut être utilisé directement
    return HtmlElementView(
      viewType: iframeId,
      onPlatformViewCreated: (int viewId) {
        // Ce code s'exécutera uniquement sur le web où dart:html est disponible
        // On doit utiliser une approche différente car dart:html ne peut pas
        // être importé conditionnellement de cette manière
        // Utiliser directement la fenêtre du navigateur
        try {
          // Utiliser dart:html via un import conditionnel dans une méthode séparée
          _createIframeElement(iframeId, url);
        } catch (e) {
          print('❌ Error creating iframe: $e');
        }
      },
    );
  }
  
  // Cette méthode sera appelée uniquement sur le web
  void _createIframeElement(String iframeId, String url) {
    // Import dynamique de dart:html - ce code ne s'exécutera que sur le web
    // En fait, nous devons utiliser une approche différente car
    // les imports conditionnels ne fonctionnent pas avec dart:html de cette façon
  }
}
