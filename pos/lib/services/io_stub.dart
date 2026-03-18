// Stub file for dart:io on web platforms
// This file provides stub implementations that throw exceptions when used
// These classes match the dart:io API structure for conditional imports

class Platform {
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

class FileMode {
  const FileMode._();
  static const FileMode write = FileMode._();
}

class RandomAccessFile {
  Future<void> writeFrom(List<int> buffer, [int start = 0, int? end]) {
    throw UnsupportedError('RandomAccessFile.writeFrom is not available on web.');
  }

  Future<void> flush() {
    throw UnsupportedError('RandomAccessFile.flush is not available on web.');
  }

  Future<void> close() {
    throw UnsupportedError('RandomAccessFile.close is not available on web.');
  }
}

class File {
  final String path;
  File(this.path);

  Future<RandomAccessFile> open({FileMode mode = FileMode.write}) {
    throw UnsupportedError('File.open is not available on web.');
  }
}

class Socket {
  Socket._();
  
  static Future<Socket> connect(
    dynamic host,
    int port, {
    Duration? timeout,
  }) {
    throw UnsupportedError('Socket.connect is not available on web. Use backend API or run on native platform.');
  }
  
  void add(List<int> data) {
    throw UnsupportedError('Socket.add is not available on web.');
  }
  
  Future<void> flush() {
    throw UnsupportedError('Socket.flush is not available on web.');
  }
  
  Future<void> close() {
    throw UnsupportedError('Socket.close is not available on web.');
  }
}

class HttpClient {
  HttpClient();
  
  Future<HttpClientRequest> getUrl(Uri url) {
    throw UnsupportedError('HttpClient.getUrl is not available on web. Use http package instead.');
  }
  
  void close({bool force = false}) {
    // No-op for stub
  }
}

class HttpHeaders {
  void set(String name, Object value) {
    // No-op for stub
  }
}

class HttpClientRequest {
  HttpHeaders headers = HttpHeaders();
  
  Future<HttpClientResponse> close() {
    throw UnsupportedError('HttpClientRequest.close is not available on web.');
  }
}

class HttpClientResponse {
  Future<void> drain([Future<dynamic>? future]) {
    throw UnsupportedError('HttpClientResponse.drain is not available on web.');
  }
}

class NetworkInterface {
  final String name;
  final int index;
  final List<InternetAddress> addresses;
  
  NetworkInterface._(this.name, this.index, this.addresses);
  
  static Future<List<NetworkInterface>> list({
    bool includeLinkLocal = false,
    InternetAddressType type = InternetAddressType.IPv4,
  }) {
    throw UnsupportedError('NetworkInterface.list is not available on web.');
  }
}

class InternetAddress {
  final String address;
  final bool isLoopback;
  
  InternetAddress._(this.address, this.isLoopback);
}

enum InternetAddressType {
  IPv4,
  IPv6,
  any,
}
