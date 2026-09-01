import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'state/app_state.dart';
import 'state/locale_provider.dart';
import 'theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/orders/order_track_screen.dart';
import 'services/notification_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase.initializeApp() reads android/app/google-services.json
  // automatically on Android - no explicit FirebaseOptions needed here.
  try {
    await Firebase.initializeApp();
    await NotificationService.init(navigatorKey: navigatorKey);
  } catch (e) {
    // If google-services.json wasn't set up (e.g. Firebase not
    // configured yet), continue without push notifications rather
    // than crashing the whole app on launch.
    debugPrint('Firebase/notifications not available: $e');
  }

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  runApp(CustomerApp(localeProvider: localeProvider));
}

class CustomerApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  const CustomerApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          title: 'Jeevi Foodie',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          navigatorKey: navigatorKey,
          locale: locale.locale,
          supportedLocales: const [Locale('en'), Locale('ta')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/order-track') {
              final orderCode = settings.arguments as String;
              return MaterialPageRoute(builder: (_) => OrderTrackScreen(orderCode: orderCode));
            }
            return null;
          },
        ),
      ),
    );
  }
}
