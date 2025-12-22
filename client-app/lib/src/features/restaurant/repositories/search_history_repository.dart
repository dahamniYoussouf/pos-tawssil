import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryRepository {
  static const String _searchHistoryKey = 'restaurant_search_history';
  static const int _maxHistoryItems = 10;

  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveSearchQuery(String query) async {
    try {
      if (query.trim().isEmpty) {
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      final currentHistory = await getSearchHistory();
      final trimmedQuery = query.trim();
      final updatedHistory = <String>[];
      updatedHistory.add(trimmedQuery);
      for (final item in currentHistory) {
        if (item.toLowerCase() != trimmedQuery.toLowerCase() &&
            updatedHistory.length < _maxHistoryItems) {
          updatedHistory.add(item);
        }
      }
      final historyJson = json.encode(updatedHistory);
      return await prefs.setString(_searchHistoryKey, historyJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_searchHistoryKey);
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeSearchQuery(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHistory = await getSearchHistory();
      final updatedHistory =
          currentHistory.where((item) => item != query).toList();
      final historyJson = json.encode(updatedHistory);
      return await prefs.setString(_searchHistoryKey, historyJson);
    } catch (e) {
      return false;
    }
  }
}
