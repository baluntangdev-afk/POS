import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

class PinIndicator extends StatelessWidget {
  const PinIndicator({super.key, required this.pin, this.color});

  final String pin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final dotSize = responsive.value<double>(phone: 18, tablet: 22, kiosk: 26);
    final spacing = responsive.value<double>(phone: 10, tablet: 12, kiosk: 14);
    final activeColor = color ?? ColorSet.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < pin.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: AnimatedContainer(
            duration: POSAnimation.normal,
            curve: Curves.easeInOut,
            width: isFilled ? dotSize : dotSize,
            height: isFilled ? dotSize : dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? activeColor : Colors.transparent,
              border: Border.all(
                color: isFilled ? activeColor : activeColor.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: isFilled
                  ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
