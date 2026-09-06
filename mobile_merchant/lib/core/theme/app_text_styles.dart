import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens. No `TextStyle(...)` literals in widgets.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);

  static TextStyle get headlineLarge =>
      _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700);

  static TextStyle get headlineMedium =>
      _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700);

  static TextStyle get titleLarge =>
      _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
}
