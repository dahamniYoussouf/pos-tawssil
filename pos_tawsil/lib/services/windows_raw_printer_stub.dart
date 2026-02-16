import 'dart:typed_data';

class WindowsRawPrinter {
  static void printBytes(String printerName, Uint8List bytes, {String? jobName}) {
    throw UnsupportedError('Windows raw printing is not supported on this platform.');
  }

  static List<Map<String, String>> listPrinters() {
    return [];
  }

  static String? getPrinterPort(String printerName) {
    return null;
  }

  static String? findPrinterNameByPort(String portName) {
    return null;
  }

  static int? getPrinterStatusFlags(String printerName) {
    return null;
  }

  static List<String> describeStatusProblems(int statusFlags) {
    return [];
  }
}
