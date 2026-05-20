import 'package:flutter/material.dart';

import 'color_set.dart';

class TypeSet {
  const TypeSet._();

  static const _primary = Color(0xFF1A1A1A);
  static const _secondary = Color(0xFF555555);
  static const _tertiary = Color(0xFF888888);

  static const h1 = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.5,
    height: 1.2,
    color: _primary,
  );

  static const h2 = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.8,
    height: 1.25,
    color: _primary,
  );

  static const h3 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.3,
    color: _primary,
  );

  static const h4 = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.35,
    color: _primary,
  );

  static const h5 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.4,
    color: _primary,
  );

  static const h6 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: _primary,
  );

  static const paragraph = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: _secondary,
  );

  static const caption = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: _secondary,
  );

  static const small = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: _tertiary,
  );

  // ─── Accent variants ───────────────────────────────────────────────────────

  static final primaryLabel = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorSet.primary,
    letterSpacing: 0.2,
  );

  static const mutedLabel = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: _tertiary,
    letterSpacing: 0.5,
  );

  static const uppercaseTag = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: _tertiary,
    height: 1.2,
  );
}
