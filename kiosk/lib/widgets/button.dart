import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (!isOutlined) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: ButtonStyle(
          foregroundColor:
              foregroundColor != null
                  ? WidgetStatePropertyAll(
                    onPressed != null ? foregroundColor! : const Color(0xFF9E9E9E),
                  )
                  : null,
          backgroundColor:
              backgroundColor != null
                  ? WidgetStatePropertyAll(
                    onPressed != null ? backgroundColor! : const Color(0xFFE0E0E0),
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
          foregroundColor:
              foregroundColor != null
                  ? WidgetStatePropertyAll(
                    onPressed != null ? foregroundColor! : const Color(0xFF9E9E9E),
                  )
                  : null,
          backgroundColor:
              backgroundColor != null
                  ? WidgetStatePropertyAll(
                    onPressed != null ? backgroundColor! : const Color(0xFFE0E0E0),
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
