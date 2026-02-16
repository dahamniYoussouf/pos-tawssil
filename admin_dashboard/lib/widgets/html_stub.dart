// Stub pour dart:html sur les plateformes non-web

class Event {}

class IFrameElement {
  String? src;
  Style style = Style();
  String? id;
  bool allowFullscreen = false;
  
  WindowBase? get contentWindow => null;
  
  Stream<Event> get onLoad => const Stream.empty();
}

class Style {
  String border = '';
  String width = '';
  String height = '';
}

class WindowBase {
  void postMessage(dynamic message, String targetOrigin) {}
}

class Document {
  Element? get body => null;
  Element? getElementById(String id) => null;
}

final document = Document();

class Element {
  void remove() {}
  void append(dynamic element) {}
}
