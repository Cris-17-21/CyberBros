import 'package:flutter/material.dart';

import 'palette.dart';

ThemeData buildCyberonTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.primary,
    brightness: Brightness.light,
    primary: Palette.primary,
    secondary: Palette.accent,
    surface: Palette.surface,
    error: const Color(0xFFEF4444),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.background,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Palette.ink,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Palette.ink,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Palette.surface,
      elevation: 1,
      shadowColor: const Color(0x140F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Palette.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.surface,
      elevation: 2,
      shadowColor: const Color(0x1A0F172A),
      indicatorColor: Palette.primaryLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Palette.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          );
        }
        return const TextStyle(
          color: Palette.inkMuted,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Palette.primary, size: 24);
        }
        return const IconThemeData(color: Palette.inkMuted, size: 24);
      }),
    ),
  );
}
