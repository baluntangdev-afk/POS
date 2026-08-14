import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bounded, floating white card that frames every auth screen (login,
/// change-PIN) instead of content sitting bare on the background — reads as
/// one staff-login panel and keeps things centered on wide/tablet screens.
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.elevated,
      ),
      child: child,
    );
  }
}
