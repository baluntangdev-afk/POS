import 'dart:io';

import 'package:flutter/material.dart';

import '../styles/color_set.dart';

/// A sticky bottom action bar that automatically adds the Android navigation-
/// bar safe-area inset so action buttons are never hidden behind the gesture
/// strip or button bar.
///
/// On Windows the bottom inset is zero — no extra padding is added.
///
/// Spec reference: "responsive_bottom_bar.dart — renders a bottom action bar
/// that automatically pads itself using MediaQuery.viewPadding.bottom on
/// Android and zero on Windows."
class ResponsiveBottomBar extends StatelessWidget {
  const ResponsiveBottomBar({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.elevation = 8,
    this.extraBottomPadding = 0,
  });

  final Widget child;
  final Color? backgroundColor;

  /// Padding applied around [child] **before** the safe-area bottom inset.
  final EdgeInsetsGeometry? padding;
  final double elevation;

  /// Additional bottom padding on top of the system inset (e.g. for aesthetics).
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final safeBottom = Platform.isAndroid
        ? MediaQuery.of(context).viewPadding.bottom + extraBottomPadding
        : extraBottomPadding;

    return Material(
      elevation: elevation,
      color: backgroundColor ?? ColorSet.background,
      child: Padding(
        padding: (padding ?? EdgeInsets.zero).add(EdgeInsets.only(bottom: safeBottom)),
        child: child,
      ),
    );
  }
}
