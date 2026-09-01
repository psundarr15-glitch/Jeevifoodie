import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final state = context.read<AppState>();
    final prefs = SharedPreferences.getInstance();

    final results = await Future.wait([
      state.bootstrap(),
      Future.delayed(const Duration(milliseconds: 1400)), // brief brand moment
    ]);
    if (!mounted) return;

    final seenOnboarding = (await prefs).getBool('seen_onboarding') ?? false;

    if (!seenOnboarding) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => state.isLoggedIn ? const RootShell() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
              child: const Icon(Icons.restaurant_menu, color: AppTheme.primaryDark, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'JEEVI FOODIE\nDELIVERY',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.3),
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.splashTagline, style: TextStyle(color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 32),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold)),
          ],
        ),
      ),
    );
  }
}
