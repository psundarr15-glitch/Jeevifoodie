import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import 'api_client.dart';

class SearchResults {
  final List<MenuItem> items;
  final List<Restaurant> restaurants;
  SearchResults({required this.items, required this.restaurants});
}

class SearchService {
  static const _recentKey = 'recent_searches';
  static const _maxRecent = 10;

  static Future<SearchResults> search(String query) async {
    final res = await ApiClient.get(ApiConfig.search(query));
    return SearchResults(
      items: (res['items'] as List? ?? []).map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList(),
      restaurants: (res['restaurants'] as List? ?? []).map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static Future<(bool, int)> toggleItemLike(int menuItemId) async {
    final res = await ApiClient.post(ApiConfig.toggleItemLike(menuItemId));
    return (res['liked'] == true, int.tryParse(res['like_count']?.toString() ?? '') ?? 0);
  }

  static Future<List<String>> recentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  static Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    list.insert(0, trimmed);
    if (list.length > _maxRecent) list.removeRange(_maxRecent, list.length);
    await prefs.setStringList(_recentKey, list);
  }

  static Future<void> removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.removeWhere((e) => e == query);
    await prefs.setStringList(_recentKey, list);
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }
}
