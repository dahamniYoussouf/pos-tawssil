// Stub pour dart:ui_web sur les plateformes non-web

class _PlatformViewRegistry {
  void registerViewFactory(String viewType, dynamic Function(int viewId) viewFactory) {}
}

final platformViewRegistry = _PlatformViewRegistry();
