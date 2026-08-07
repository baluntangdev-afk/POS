import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Extended FAB with the brand gradient, shared so every tab's primary
/// "Add" action looks like the same app instead of falling back to the
/// default Material FAB color on some screens and not others.
class GradientFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const GradientFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: AppShadows.card,
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}
