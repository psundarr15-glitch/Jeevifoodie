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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide = Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> _loaderFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
                    child: const Icon(Icons.restaurant_menu, color: AppTheme.primaryDark, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      const Text(
                        'JEEVI FOODIE\nDELIVERY',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      Text(AppLocalizations.of(context)!.splashTagline, style: TextStyle(color: Colors.white.withOpacity(0.85))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _loaderFade,
                child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
