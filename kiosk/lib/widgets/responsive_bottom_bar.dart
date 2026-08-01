import 'dart:io';

import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../theme/pos_design.dart';

/// Sticky bottom action bar that automatically adds the Android navigation-bar
/// safe-area inset so action buttons are never hidden behind the gesture strip.
///
/// On Windows the bottom inset is zero — no extra padding is added.
class ResponsiveBottomBar extends StatelessWidget {
  const ResponsiveBottomBar({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.extraBottomPadding = 0,
  });

  final Widget child;
  final Color? backgroundColor;

  /// Padding applied around [child] before the safe-area bottom inset.
  final EdgeInsetsGeometry? padding;

  /// Additional bottom padding on top of the system inset.
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final safeBottom = Platform.isAndroid
        ? MediaQuery.of(context).viewPadding.bottom + extraBottomPadding
        : extraBottomPadding;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? ColorSet.background,
        border: Border(
          top: BorderSide(color: POSColors.borderSubtle, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: (padding ?? EdgeInsets.zero).add(EdgeInsets.only(bottom: safeBottom)),
        child: child,
      ),
    );
  }
}
