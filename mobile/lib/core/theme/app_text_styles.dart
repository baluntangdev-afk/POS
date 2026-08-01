import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final displayLg = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static final displayMd = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2);
  static final headingLg = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static final headingMd = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static final headingSm = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static final bodyLg = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static final bodyMd = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static final bodySm = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static final labelLg = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.1);
  static final labelMd = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.5);
  static final priceLg = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);
  static final priceMd = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2);
}
