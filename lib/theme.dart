import 'package:flutter/material.dart';

import 'data/poll_repository.dart';

class AppColors {
  static const orange = Color(0xFFF47A1F);
  static const orangeDark = Color(0xFFE5640C);
  static const green = Color(0xFF1E9A3F);
  static const greenDark = Color(0xFF17803A);
  static const ink = Color(0xFF1B1D21);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE6E8EC);
  static const bg = Color(0xFFF6F7F9);
  static const blue = Color(0xFF2F6FDB);
  static const red = Color(0xFFE53935);
  static const amber = Color(0xFFF6B21A);
  static const grey = Color(0xFFB8BEC8);

  static Color race(RaceStatus s) => switch (s) {
        RaceStatus.clearLead => green,
        RaceStatus.close => amber,
        RaceStatus.tight => red,
        RaceStatus.noData => grey,
      };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.orange,
    primary: AppColors.orange,
    secondary: AppColors.green,
    surface: Colors.white,
  );
  const radius = BorderRadius.all(Radius.circular(12));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.orange, width: 1.5)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.orange,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.orange,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.border,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.orange.withValues(alpha: 0.12),
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.orange : AppColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.orange : AppColors.muted)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.orange.withValues(alpha: 0.12),
      selectedIconTheme: const IconThemeData(color: AppColors.orange),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.green : null),
    ),
  );
}
