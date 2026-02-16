// Stub file pour le web - WebView n'est pas supporté sur le web
// Ce fichier est utilisé comme remplacement pour webview_flutter sur le web

import 'package:flutter/material.dart';

class WebViewController {
  WebViewController();
  
  factory WebViewController.fromPlatformCreationParams(dynamic params) {
    return WebViewController();
  }
  
  void setJavaScriptMode(JavaScriptMode mode) {}
  void setBackgroundColor(Color color) {}
  void setNavigationDelegate(NavigationDelegate delegate) {}
  void addJavaScriptChannel(String name, {required void Function(JavaScriptMessage) onMessageReceived}) {}
  
  Future<void> runJavaScript(String script) async {}
  Future<void> reload() async {}
  Future<void> loadRequest(Uri uri) async {}
}

class NavigationDelegate {
  final void Function(String)? onPageStarted;
  final void Function(int)? onProgress;
  final void Function(String)? onPageFinished;
  final void Function(WebResourceError)? onWebResourceError;
  
  const NavigationDelegate({
    this.onPageStarted,
    this.onProgress,
    this.onPageFinished,
    this.onWebResourceError,
  });
}

class WebResourceError {
  final String description;
  WebResourceError({required this.description});
}

class WebViewWidget extends StatelessWidget {
  final WebViewController controller;
  const WebViewWidget({super.key, required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebViewPlatform {
  static dynamic get instance => null;
}

class PlatformWebViewControllerCreationParams {
  const PlatformWebViewControllerCreationParams();
}

class WebKitWebViewPlatform {}

class WebKitWebViewControllerCreationParams extends PlatformWebViewControllerCreationParams {
  final bool allowsInlineMediaPlayback;
  final dynamic mediaTypesRequiringUserAction; // Peut être List ou Set
  
  WebKitWebViewControllerCreationParams({
    required this.allowsInlineMediaPlayback,
    required this.mediaTypesRequiringUserAction,
  });
}

class PlaybackMediaTypes {
  const PlaybackMediaTypes();
}

class JavaScriptMode {
  static const unrestricted = JavaScriptMode._();
  const JavaScriptMode._();
}

class JavaScriptMessage {
  final String message;
  JavaScriptMessage({required this.message});
}
