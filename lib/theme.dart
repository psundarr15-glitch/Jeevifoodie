import 'package:flutter/material.dart';

/// Jeevi Foodie consumer design system.
///
/// UX direction: warm, appetising, friendly and image-first.  The theme is
/// deliberately shared through Material widgets so existing screens get the
/// new visual language without changing their business logic.
class AppTheme {
  static const primary = Color(0xFFD6291B);
  static const primaryDark = Color(0xFF8E1610);
  static const gold = Color(0xFFF7B500);
  static const success = Color(0xFF159447);
  static const canvas = Color(0xFFFFFAF4);
  static const surfaceTint = Color(0xFFFFF1E7);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF211A17) : Colors.white;
  static Color scaffoldBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1F1B19);
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF746B66);
  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE8DED7);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: Color(0xFF1F1B19),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF1F1B19)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: Color(0xFFE6B7B2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: Color(0xFF9A918B)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8DED7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8DED7))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFC62828))),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceTint,
        selectedColor: primary.withOpacity(.12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F1B19)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        height: 72,
        elevation: 8,
        indicatorColor: primary.withOpacity(.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: states.contains(WidgetState.selected) ? primary : const Color(0xFF746B66),
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? primary : const Color(0xFF746B66),
            )),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEDE4DE), thickness: 1, space: 1),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF151110),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false, surfaceTintColor: Colors.transparent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.6)),
      ),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
      navigationBarTheme: NavigationBarThemeData(height: 72, indicatorColor: primary.withOpacity(.25)),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? Colors.white : const Color(0xFF1F1B19);
    final muted = brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF746B66);
    return TextTheme(
      headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: base, height: 1.15),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: base),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: base),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: base, height: 1.4),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: base),
    );
  }
}
