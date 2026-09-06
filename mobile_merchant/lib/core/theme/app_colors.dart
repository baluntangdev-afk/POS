import 'package:flutter/material.dart';

/// Flat palette of design tokens. No color literals anywhere else in the app.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1B7A8C);
  static const Color primaryDark = Color(0xFF125A68);
  static const Color secondary = Color(0xFFBCBE68);
  static const Color background = Color(0xFFF3F1ED);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFDCD9D3);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFC62828);
}
