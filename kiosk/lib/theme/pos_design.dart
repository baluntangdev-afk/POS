import 'package:flutter/material.dart';
import '../styles/color_set.dart';

abstract class POSSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

abstract class POSRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}

abstract class POSShadow {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> panel = [
    BoxShadow(color: Color(0x14000000), blurRadius: 32, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 40, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> headerBottom = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: ColorSet.primary.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

mixin POSGradient {
  static const LinearGradient primary = LinearGradient(
    colors: ColorSet.gradientBg,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient header = LinearGradient(
    colors: [Color(0xFF1B7A8C), Color(0xFF1A8570)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardAccent = LinearGradient(
    colors: [Color(0xFF1B7A8C), Color(0xFF2A9CAF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient primaryFaded = LinearGradient(
    colors: [ColorSet.secondary.withValues(alpha: 0.9), ColorSet.primary.withValues(alpha: 0.9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract class POSColors {
  static const Color surfaceBase = Colors.white;
  static const Color surfaceElevated = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF7F7F5);
  static const Color surfaceOverlay = Color(0xFFF0EEE9);
  static const Color borderDefault = Color(0xFFEAEAEA);
  static const Color borderSubtle = Color(0xFFF0F0F0);
  static const Color borderStrong = Color(0xFFD5D5D5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textTertiary = Color(0xFF888888);
  static const Color textDisabled = Color(0xFFBBBBBB);
  static const Color iconDefault = Color(0xFF444444);
  static const Color iconSubtle = Color(0xFF888888);
}

abstract class POSAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve ease = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve spring = Curves.elasticOut;
}
