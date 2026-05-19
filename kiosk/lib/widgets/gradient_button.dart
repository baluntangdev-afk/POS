import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';

/// A full-width action button used for primary actions throughout the app.
///
/// Supports two visual modes:
/// - [GradientButton] (default): brand gradient fill, pill shape.
/// - [GradientButton.solid]: solid background color, pill shape.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  })  : _useGradient = true,
        _backgroundColor = null,
        _foregroundColor = null;

  const GradientButton.solid({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    Color backgroundColor = ColorSet.primary,
    Color foregroundColor = ColorSet.light,
  })  : _useGradient = false,
        _backgroundColor = backgroundColor,
        _foregroundColor = foregroundColor;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool _useGradient;
  final Color? _backgroundColor;
  final Color? _foregroundColor;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    BoxDecoration decoration;
    if (!_isEnabled) {
      decoration = BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(r.buttonRadius),
      );
    } else if (_useGradient) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorSet.secondary.withValues(alpha: 0.85),
            ColorSet.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.buttonRadius),
      );
    } else {
      decoration = BoxDecoration(
        color: _backgroundColor ?? ColorSet.primary,
        borderRadius: BorderRadius.circular(r.buttonRadius),
      );
    }

    return GestureDetector(
      onTap: _isEnabled ? onPressed : null,
      child: Container(
        height: r.buttonHeight,
        width: double.infinity,
        decoration: decoration,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: ColorSet.light,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: r.fontBody,
                    fontWeight: FontWeight.w500,
                    color: _isEnabled
                        ? (_foregroundColor ?? ColorSet.light)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
        ),
      ),
    );
  }
}
