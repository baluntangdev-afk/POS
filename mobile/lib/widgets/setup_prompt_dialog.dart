import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum SetupPromptType { info, warning, error }

Future<void> showSetupPromptDialog(
  BuildContext context, {
  required String message,
  String? title,
  SetupPromptType type = SetupPromptType.warning,
  String primaryButtonText = 'OK',
  String? secondaryButtonText,
  String? tertiaryButtonText,
  VoidCallback? onPrimaryPressed,
  VoidCallback? onSecondaryPressed,
  VoidCallback? onTertiaryPressed,
  bool barrierDismissible = true,
}) {
  assert(
    secondaryButtonText == null || onSecondaryPressed != null,
    'secondaryButtonText provided without onSecondaryPressed callback',
  );
  assert(
    tertiaryButtonText == null || onTertiaryPressed != null,
    'tertiaryButtonText provided without onTertiaryPressed callback',
  );
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: AppColors.overlay,
    builder: (context) => SetupPromptDialog(
      message: message,
      title: title,
      type: type,
      primaryButtonText: primaryButtonText,
      secondaryButtonText: secondaryButtonText,
      tertiaryButtonText: tertiaryButtonText,
      onPrimaryPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
      onSecondaryPressed: onSecondaryPressed,
      onTertiaryPressed: onTertiaryPressed,
    ),
  );
}

class SetupPromptDialog extends StatelessWidget {
  const SetupPromptDialog({
    super.key,
    required this.message,
    this.title,
    this.type = SetupPromptType.warning,
    this.primaryButtonText = 'OK',
    this.secondaryButtonText,
    this.tertiaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.onTertiaryPressed,
  });

  final String message;
  final String? title;
  final SetupPromptType type;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final String? tertiaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onTertiaryPressed;

  Color get _accentColor {
    switch (type) {
      case SetupPromptType.error:
        return AppColors.error;
      case SetupPromptType.warning:
        return AppColors.warning;
      case SetupPromptType.info:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (type) {
      case SetupPromptType.error:
        return Icons.error_rounded;
      case SetupPromptType.warning:
        return Icons.warning_rounded;
      case SetupPromptType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 340,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _accentColor, size: 30),
            ),
            const SizedBox(height: 16),
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _ActionButtons(
              primaryButtonText: primaryButtonText,
              secondaryButtonText: secondaryButtonText,
              onPrimaryPressed: onPrimaryPressed,
              onSecondaryPressed: onSecondaryPressed,
              accentColor: _accentColor,
            ),
            if (tertiaryButtonText != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onTertiaryPressed,
                child: Text(
                  tertiaryButtonText!,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    required this.accentColor,
  });

  final String primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (secondaryButtonText != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                secondaryButtonText!,
                style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                primaryButtonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          primaryButtonText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}
