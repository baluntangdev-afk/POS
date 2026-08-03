import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// A primary-action button styled like [FilledButton] but painted with the
/// brand gradient instead of a flat fill, matching the kiosk app's CTA style.
/// Drop-in replacement for `FilledButton(onPressed: ..., child: ...)` on the
/// app's highest-traffic actions (checkout, confirm payment, add to cart).
class GradientFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double minHeight;
  final double borderRadius;

  const GradientFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.minHeight = AppSpacing.touchMin,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: disabled ? null : AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Container(
              constraints: BoxConstraints(minHeight: minHeight),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
