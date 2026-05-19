import 'package:flutter/material.dart';

import 'breakpoint.dart';

class ResponsiveValue {
  const ResponsiveValue._(this.context);

  const ResponsiveValue.of(BuildContext context) : this._(context);

  final BuildContext context;

  static const double _ratioTablet = 0.75;
  static const double _ratioPhone = 0.5;

  T value<T>({required T kiosk, T? tablet, T? phone}) {
    final Breakpoint(:deviceType) = context.breakpoint;
    if (deviceType == DeviceType.phone) return phone ?? tablet ?? kiosk;
    if (deviceType == DeviceType.tablet) return tablet ?? kiosk;
    return kiosk;
  }

  double scale(double value) {
    final Breakpoint(:deviceType) = context.breakpoint;
    if (deviceType == DeviceType.phone) return value * _ratioPhone;
    if (deviceType == DeviceType.tablet) return value * _ratioTablet;
    return value;
  }

  // ─── Structural ──────────────────────────────────────────────────────────
  double get appBarHeight => value(kiosk: 120.0, tablet: 90.0, phone: 70.0);
  double get buttonHeight => value(kiosk: 64.0, tablet: 56.0, phone: 48.0);
  double get buttonRadius => buttonHeight / 2;

  // ─── Spacing / padding ───────────────────────────────────────────────────
  double get hPagePadding => value(kiosk: 32.0, tablet: 24.0, phone: 16.0);
  double get vPagePadding => value(kiosk: 24.0, tablet: 18.0, phone: 12.0);
  double get hButtonMargin => value(kiosk: 64.0, tablet: 48.0, phone: 24.0);
  double get spacingSm => value(kiosk: 8.0, tablet: 6.0, phone: 4.0);
  double get spacingMd => value(kiosk: 16.0, tablet: 12.0, phone: 8.0);
  double get spacingLg => value(kiosk: 32.0, tablet: 24.0, phone: 16.0);
  double get spacingXl => value(kiosk: 48.0, tablet: 36.0, phone: 24.0);

  // ─── Icon sizes ──────────────────────────────────────────────────────────
  double get iconSm => value(kiosk: 24.0, tablet: 20.0, phone: 16.0);
  double get iconMd => value(kiosk: 32.0, tablet: 24.0, phone: 20.0);
  double get iconLg => value(kiosk: 48.0, tablet: 36.0, phone: 28.0);
  double get iconBack => value(kiosk: 48.0, tablet: 32.0, phone: 24.0);

  // ─── Font sizes ──────────────────────────────────────────────────────────
  double get fontSm => value(kiosk: 20.0, tablet: 16.0, phone: 12.0);
  double get fontMd => value(kiosk: 28.0, tablet: 20.0, phone: 14.0);
  double get fontLg => value(kiosk: 36.0, tablet: 24.0, phone: 18.0);
  double get fontTitle => value(kiosk: 36.0, tablet: 28.0, phone: 20.0);
  double get fontBody => value(kiosk: 24.0, tablet: 18.0, phone: 14.0);
  double get fontCaption => value(kiosk: 20.0, tablet: 16.0, phone: 12.0);

  // ─── Extended typography (spec minimums) ─────────────────────────────────
  /// Hero text on onboarding/splash — ≥48px tablet, ≥56px kiosk.
  double get fontHero => value(kiosk: 56.0, tablet: 48.0, phone: 36.0);
  /// Screen headings — ≥32px tablet, ≥48px kiosk.
  double get fontHeading => value(kiosk: 48.0, tablet: 32.0, phone: 24.0);
  /// Form labels and prominent UI labels — ≥20px tablet, ≥24px kiosk.
  double get fontLabel => value(kiosk: 24.0, tablet: 20.0, phone: 16.0);

  // ─── Touch targets ───────────────────────────────────────────────────────
  /// Minimum tap-target size — 72px kiosk, 56px tablet.
  double get touchTargetMin => value(kiosk: 72.0, tablet: 56.0, phone: 48.0);
  /// Preferred height for primary action buttons.
  double get primaryBtnHeight => value(kiosk: 80.0, tablet: 64.0, phone: 56.0);

  // ─── Keypad ──────────────────────────────────────────────────────────────
  /// Square key size for PIN and cash entry pads — 88px kiosk, 72px tablet.
  double get keypadKeySize => value(kiosk: 88.0, tablet: 72.0, phone: 56.0);

  // ─── Layout helpers ──────────────────────────────────────────────────────
  /// Card corner radius — 24px kiosk, 16px tablet.
  double get cardRadius => value(kiosk: 24.0, tablet: 16.0, phone: 12.0);
  /// Width of the fixed left category sidebar (kiosk only, 0 on tablet/phone).
  double get sidebarWidth => value(kiosk: 240.0, tablet: 0.0, phone: 0.0);
  /// Width of the fixed right cart panel (kiosk only, 0 on tablet/phone).
  double get cartPanelWidth => value(kiosk: 320.0, tablet: 0.0, phone: 0.0);

  // ─── Common EdgeInsets ───────────────────────────────────────────────────
  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: hPagePadding);
  EdgeInsets get pageInsets =>
      EdgeInsets.symmetric(horizontal: hPagePadding, vertical: vPagePadding);
  EdgeInsets get buttonMarginH => EdgeInsets.symmetric(horizontal: hButtonMargin);
}

extension ResponsiveValueContext on BuildContext {
  ResponsiveValue get responsive => ResponsiveValue.of(this);
}
