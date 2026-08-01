import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../styles/responsive/breakpoint.dart';
import '../styles/responsive/responsive_value.dart';

enum DialogType { success, error, warning, info }

Future<void> showMessageDialog(
  BuildContext context, {
  required String message,
  String? title,
  DialogType type = DialogType.info,
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
    onSecondaryPressed == null || secondaryButtonText != null,
    'onSecondaryPressed provided without secondaryButtonText',
  );
  assert(
    tertiaryButtonText == null || onTertiaryPressed != null,
    'tertiaryButtonText provided without onTertiaryPressed callback',
  );
  assert(
    onTertiaryPressed == null || tertiaryButtonText != null,
    'onTertiaryPressed provided without tertiaryButtonText',
  );
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    builder:
        (context) => MessageDialog(
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

class MessageDialog extends StatelessWidget {
  const MessageDialog({
    super.key,
    required this.message,
    this.title,
    this.type = DialogType.info,
    this.primaryButtonText = 'OK',
    this.secondaryButtonText,
    this.tertiaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.onTertiaryPressed,
  });

  final String message;
  final String? title;
  final DialogType type;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final String? tertiaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onTertiaryPressed;

  Color get _accentColor {
    switch (type) {
      case DialogType.success:
        return ColorSet.success;
      case DialogType.error:
        return ColorSet.danger;
      case DialogType.warning:
        return ColorSet.warning;
      case DialogType.info:
        return ColorSet.primary;
    }
  }

  IconData get _icon {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_rounded;
      case DialogType.error:
        return Icons.error_rounded;
      case DialogType.warning:
        return Icons.warning_rounded;
      case DialogType.info:
        return Icons.info_rounded;
    }
  }

  String get _defaultTitle {
    switch (type) {
      case DialogType.success:
        return 'Success';
      case DialogType.error:
        return 'Error';
      case DialogType.warning:
        return 'Warning';
      case DialogType.info:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;

    double width, padding, iconSize, titleSize, messageSize;

    if (breakpoint.isPhone) {
      width = 320;
      padding = 20;
      iconSize = 40;
      titleSize = 25;
      messageSize = 18;
    } else if (breakpoint.isTablet) {
      width = 360;
      padding = 22;
      iconSize = 50;
      titleSize = 28;
      messageSize = 20;
    } else {
      width = 380;
      padding = 24;
      iconSize = 60;
      titleSize = 30;
      messageSize = 22;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ColorSet.light,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconHeader(icon: _icon, accentColor: _accentColor, iconSize: iconSize),
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
              child: Column(
                children: [
                  Text(
                    title ?? _defaultTitle,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: ColorSet.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: titleSize * 0.5),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: messageSize,
                      fontWeight: FontWeight.w400,
                      color: ColorSet.text.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: padding),
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
                          color: ColorSet.text.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconHeader extends StatelessWidget {
  const _IconHeader({required this.icon, required this.accentColor, required this.iconSize});

  final IconData icon;
  final Color accentColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final containerSize = iconSize * 1.8;
    return Padding(
      padding: EdgeInsets.only(top: containerSize * 0.4, bottom: containerSize * 0.25),
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: iconSize),
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
                style: TextStyle(
                  color: ColorSet.light,
                  fontWeight: FontWeight.w600,
                  fontSize: context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 22),
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
          style: TextStyle(
            color: ColorSet.light,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 22),
          ),
        ),
      ),
    );
  }
}
