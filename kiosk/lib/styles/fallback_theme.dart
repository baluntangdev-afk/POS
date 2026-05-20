import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'color_set.dart';

final fallbackTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ColorSet.primary,
    primary: ColorSet.primary,
    onPrimary: Colors.white,
    secondary: ColorSet.secondary,
    onSecondary: Colors.white,
    tertiary: ColorSet.tertiary,
    error: ColorSet.danger,
    surface: Colors.white,
    onSurface: const Color(0xFF1A1A1A),
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: ColorSet.primary),
  scaffoldBackgroundColor: ColorSet.background,
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF1A1A1A)),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF1A1A1A)),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF1A1A1A)),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF1A1A1A)),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF666666)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorSet.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 0,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ColorSet.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorSet.primary,
      side: const BorderSide(color: ColorSet.primary, width: 1.5),
      minimumSize: const Size(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ColorSet.primary,
      minimumSize: const Size(0, 48),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF7F7F7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ColorSet.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ColorSet.danger, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ColorSet.danger, width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 15),
    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
    prefixIconColor: const Color(0xFF888888),
    suffixIconColor: const Color(0xFF888888),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return ColorSet.primary;
      return Colors.transparent;
    }),
    side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: ColorSet.primary.withValues(alpha: 0.12),
    side: const BorderSide(color: Color(0xFFDDDDDD)),
    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFEEEEEE),
    thickness: 1,
    space: 1,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    backgroundColor: const Color(0xFF1A1A1A),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    backgroundColor: Colors.white,
    elevation: 8,
    titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
    contentTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF555555)),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: ColorSet.primary),
);
