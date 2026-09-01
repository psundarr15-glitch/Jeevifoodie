import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  int cartCount = 0;
  Map<String, dynamic>? currentUser;

  Future<void> bootstrap() async {
    final token = await ApiClient.getToken();
    isLoggedIn = token != null;
    if (isLoggedIn) {
      await refreshCartCount();
      // Re-attach the FCM token now that we have an auth token - covers
      // the case where Firebase got a token before login happened.
      NotificationService.registerCurrentToken();
    }
    notifyListeners();
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
