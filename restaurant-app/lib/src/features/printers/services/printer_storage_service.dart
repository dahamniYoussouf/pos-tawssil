import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant_printer.dart';

class PrinterStorageService {
  static const String _printersKey = 'restaurant_printers_v1';

  Future<List<RestaurantPrinter>> loadPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_printersKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((item) => RestaurantPrinter.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePrinters(List<RestaurantPrinter> printers) async {
    final prefs = await SharedPreferences.getInstance();
    final list = printers.map((p) => p.toMap()).toList();
    await prefs.setString(_printersKey, jsonEncode(list));
  }

  Future<void> addPrinter(RestaurantPrinter printer) async {
    final printers = await loadPrinters();
    printers.add(printer);
    await savePrinters(printers);
  }

  Future<void> updatePrinter(RestaurantPrinter printer) async {
    final printers = await loadPrinters();
    final index = printers.indexWhere((p) => p.id == printer.id);
    if (index == -1) return;
    printers[index] = printer;
    await savePrinters(printers);
  }

  Future<void> deletePrinter(String printerId) async {
    final printers = await loadPrinters();
    printers.removeWhere((p) => p.id == printerId);
    await savePrinters(printers);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printersKey);
  }
}
