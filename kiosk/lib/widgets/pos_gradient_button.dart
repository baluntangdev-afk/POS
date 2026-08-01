import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../theme/pos_design.dart';

class POSGradientButton extends StatelessWidget {
  const POSGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 64,
    this.borderRadius,
    this.gradient = POSGradient.primary,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double? borderRadius;
  final Gradient gradient;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? height / 2;
    final canTap = onTap != null && enabled && !isLoading;

    return AnimatedContainer(
      duration: POSAnimation.fast,
      height: height,
      decoration: BoxDecoration(
        gradient: canTap ? gradient : null,
        color: canTap ? null : const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: canTap ? POSShadow.button : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: canTap ? onTap : null,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: canTap ? Colors.white : const Color(0xFF9E9E9E), size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: canTap ? Colors.white : const Color(0xFF9E9E9E),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class POSOutlineButton extends StatelessWidget {
  const POSOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 56,
    this.color = ColorSet.primary,
    this.icon,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final Color color;
  final IconData? icon;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 14.0;
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon != null ? Icon(icon, size: 18) : null,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
