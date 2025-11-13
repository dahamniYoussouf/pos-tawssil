import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:delivery_app/src/core/models/wilaya_model.dart';

class WilayaService {
  static List<WilayaModel>? _wilayas;
  static const String _assetPath = 'assets/data/wilayas.json';

  static Future<List<WilayaModel>> loadWilayas() async {
    if (_wilayas != null) {
      return _wilayas!;
    }

    try {
      final String response = await rootBundle.loadString(_assetPath);
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      _wilayas = data.map((json) => WilayaModel.fromJson(json as Map<String, dynamic>)).toList();
      return _wilayas!;
    } catch (e) {
      throw Exception('Failed to load wilayas: $e');
    }
  }

  static Future<WilayaModel?> getWilayaByName(String name) async {
    final wilayas = await loadWilayas();
    try {
      return wilayas.firstWhere((wilaya) => wilaya.name == name);
    } catch (e) {
      return null;
    }
  }

  static Future<WilayaModel?> getWilayaByCode(int code) async {
    final wilayas = await loadWilayas();
    try {
      return wilayas.firstWhere((wilaya) => wilaya.code == code);
    } catch (e) {
      return null;
    }
  }
}
