import 'package:flutter/material.dart';

import '../theme/pos_design.dart';

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.label,
    this.foregroundColor,
    this.backgroundColor,
    this.leading,
    this.trailing,
    this.onPressed,
  }) : isOutlined = false,
       assert(
         leading == null || trailing == null,
         'Provide only one of either leading or trailing',
       );

  const Button.outlined({
    super.key,
    required this.label,
    this.foregroundColor,
    this.backgroundColor,
    this.leading,
    this.trailing,
    this.onPressed,
  }) : isOutlined = true,
       assert(
         leading == null || trailing == null,
         'Provide only one of either leading or trailing',
       );

  final Widget label;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Widget? leading;
  final Widget? trailing;
  final void Function()? onPressed;
  final bool isOutlined;

  static const _shape = WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(POSRadius.md))),
  );
  static const _minSize = WidgetStatePropertyAll(Size(0, 56));
  static const _padding = WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    if (!isOutlined) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize: _minSize,
          padding: _padding,
          shape: _shape,
          foregroundColor:
              foregroundColor != null
                  ? WidgetStatePropertyAll(
                    disabled ? const Color(0xFF9E9E9E) : foregroundColor!,
                  )
                  : null,
          backgroundColor:
              backgroundColor != null
                  ? WidgetStatePropertyAll(
                    disabled ? const Color(0xFFE0E0E0) : backgroundColor!,
                  )
                  : null,
        ),
        icon: leading ?? trailing,
        iconAlignment: leading != null ? IconAlignment.start : IconAlignment.end,
        label: label,
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize: _minSize,
          padding: _padding,
          shape: _shape,
          foregroundColor:
              foregroundColor != null
                  ? WidgetStatePropertyAll(
                    disabled ? const Color(0xFF9E9E9E) : foregroundColor!,
                  )
                  : null,
          backgroundColor:
              backgroundColor != null
                  ? WidgetStatePropertyAll(
                    disabled ? const Color(0xFFE0E0E0) : backgroundColor!,
                  )
                  : null,
        ),
        icon: leading ?? trailing,
        iconAlignment: leading != null ? IconAlignment.start : IconAlignment.end,
        label: label,
      );
    }
  }
}
