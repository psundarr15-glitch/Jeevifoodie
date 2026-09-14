import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  int cartCount = 0;
  Map<String, dynamic>? currentUser;
  bool notificationsEnabled = true;

  static const _notifPrefsKey = 'notifications_enabled';

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool(_notifPrefsKey) ?? true;

    final token = await ApiClient.getToken();
    isLoggedIn = token != null;
    if (isLoggedIn) {
      await Future.any([
        refreshCartCount(),
        Future.delayed(const Duration(seconds: 5)),
      ]);
      // Re-attach the FCM token now that we have an auth token - covers
      // the case where Firebase got a token before login happened.
      NotificationService.registerCurrentToken();
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifPrefsKey, value);
    if (value) {
      NotificationService.registerCurrentToken();
    } else {
      NotificationService.unregisterCurrentToken();
    }
  }

  void setLoggedIn(Map<String, dynamic> user) {
    isLoggedIn = true;
    currentUser = user;
    notifyListeners();
    refreshCartCount();
    NotificationService.registerCurrentToken();
  }

  void logout() {
    isLoggedIn = false;
    currentUser = null;
    cartCount = 0;
    notifyListeners();
  }

  Future<void> refreshCartCount() async {
    try {
      final cart = await CartService.view();
      cartCount = cart.count;
      notifyListeners();
    } catch (_) {
      // not logged in / network issue - ignore, badge just stays as-is
    }
  }
}
