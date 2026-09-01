import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';

/// Handles Firebase Cloud Messaging: permission, token registration
/// with the backend, topic subscription for broadcast/promo pushes,
/// and foreground/tap message handling.
///
/// Background/terminated messages are shown by the OS automatically
/// (including any banner image, via the `notification.image` field the
/// backend sends). Foreground messages are shown ourselves as a real
/// system-style banner notification (with the same image, if any) via
/// flutter_local_notifications - FCM does NOT show a system tray
/// notification for foreground messages by default, only a plain
/// in-app snackbar would appear without this.
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Topic the admin panel's "Send to all customers" broadcast uses.
  static const promotionsTopic = 'promotions';

  static const _channelId = 'order_updates';
  static const _channelName = 'Order & offer updates';

  /// Called once, after Firebase.initializeApp() in main().
  static Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_notify')),
      onDidReceiveNotificationResponse: (response) {
        final orderCode = response.payload;
        final nav = navigatorKey.currentState;
        if (nav != null && orderCode != null && orderCode.isNotEmpty) {
          nav.pushNamed('/order-track', arguments: orderCode);
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Order status updates and offers',
          importance: Importance.high,
        ));

    // Broadcast/promotional notifications (offers, announcements) go to
    // everyone subscribed to this topic - doesn't require login.
    await _messaging.subscribeToTopic(promotionsTopic);

    // Register the current token, and again whenever it's refreshed.
    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);
    _messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App was in background and the user tapped the (system-shown) notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(message, navigatorKey));

    // App was fully closed (terminated) and launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage, navigatorKey);
  }

  /// Call again right after a successful login, in case permission/token
  /// weren't available yet at app-start (e.g. user wasn't logged in
  /// when init() ran, so there was no auth token to attach the request to).
  static Future<void> registerCurrentToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);
  }

  static Future<void> _registerToken(String token) async {
    try {
      await ApiClient.post(ApiConfig.deviceToken, {'fcm_token': token, 'platform': 'android'});
    } catch (_) {
      // Not logged in yet, or a transient network error - fine, we'll
      // try again on next launch or token refresh.
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final imageUrl = message.notification?.android?.imageUrl ?? message.data['image'];
    final orderCode = message.data['order_code'];

    Uint8List? imageBytes;
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(imageUrl.toString()));
        if (res.statusCode == 200) imageBytes = res.bodyBytes;
      } catch (_) {
        // Image download failed - fall back to a plain (no-image) notification below.
      }
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: imageBytes != null
          ? BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              largeIcon: ByteArrayAndroidBitmap(imageBytes),
              contentTitle: title,
              summaryText: body,
            )
          : BigTextStyleInformation(body, contentTitle: title),
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: orderCode?.toString(),
    );
  }

  static void _handleTap(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final orderCode = message.data['order_code'];
    final nav = navigatorKey.currentState;
    if (nav == null || orderCode == null) return;
    nav.pushNamed('/order-track', arguments: orderCode.toString());
  }
}
