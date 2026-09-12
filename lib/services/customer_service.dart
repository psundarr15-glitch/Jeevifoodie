import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import 'api_client.dart';

class HomeData {
  final List<Category> categories;
  final List<Restaurant> restaurants;
  final List<Restaurant> nearbyStores;
  final List<Restaurant> newRestaurants;
  final List<MenuItem> popularItems;
  final List<Map<String, dynamic>> coupons;
  HomeData({
    required this.categories,
    required this.restaurants,
    required this.nearbyStores,
    required this.newRestaurants,
    required this.popularItems,
    required this.coupons,
  });
}

class RestaurantMenuData {
  final Restaurant restaurant;
  final Map<String, List<MenuItem>> menu; // grouped by category name

  RestaurantMenuData({required this.restaurant, required this.menu});
}

class CustomerService {
  /// Best-effort current location for the "Nearby Stores" section - never
  /// throws or blocks the home page on missing permission/GPS, just falls
  /// back to no coordinates (backend then shows newest restaurants instead).
  static Future<Position?> _bestEffortLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  static Future<HomeData> home() async {
    final pos = await _bestEffortLocation();
    var url = ApiConfig.home;
    if (pos != null) {
      url += '?lat=${pos.latitude}&lng=${pos.longitude}';
    }
    final res = await ApiClient.get(url);
    return HomeData(
      categories: (res['categories'] as List? ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      restaurants: (res['restaurants'] as List? ?? [])
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearbyStores: (res['nearby_stores'] as List? ?? [])
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList(),
      newRestaurants: (res['new_restaurants'] as List? ?? [])
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularItems: (res['popular_items'] as List? ?? [])
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      coupons: (res['coupons'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
  }

  static Future<List<Map<String, dynamic>>> coupons() async {
    final res = await ApiClient.get(ApiConfig.coupons);
    return (res['coupons'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Restaurant>> restaurants({String? query}) async {
    var url = ApiConfig.restaurants;
    if (query != null && query.isNotEmpty) {
      url += '?q=${Uri.encodeQueryComponent(query)}';
    }
    final res = await ApiClient.get(url);
    return (res['restaurants'] as List? ?? [])
        .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<RestaurantMenuData> restaurantMenu(int id) async {
    final res = await ApiClient.get(ApiConfig.restaurantMenu(id));
    final restaurant = Restaurant.fromJson(res['restaurant'] as Map<String, dynamic>);
    // A restaurant with zero menu items may send `menu: []` instead of
    // `menu: {}` (PHP/JSON quirk) - treat that the same as "no items"
    // instead of crashing on the type cast.
    final rawMenuField = res['menu'];
    final rawMenu = rawMenuField is Map<String, dynamic> ? rawMenuField : <String, dynamic>{};
    final menu = <String, List<MenuItem>>{};
    rawMenu.forEach((cat, items) {
      menu[cat] = (items as List).map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
    });
    return RestaurantMenuData(restaurant: restaurant, menu: menu);
  }

  /// Returns (liked, likeCount).
  static Future<(bool, int)> toggleLike(int restaurantId) async {
    final res = await ApiClient.post(ApiConfig.toggleLike(restaurantId));
    return (res['liked'] == true, int.tryParse(res['like_count']?.toString() ?? '') ?? 0);
  }
}
