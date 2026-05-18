import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';

class PinIndicator extends StatelessWidget {
  const PinIndicator({super.key, required this.pin, this.color});

  final String pin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final dotSize = responsive.value<double>(phone: 20, tablet: 25, kiosk: 30);
    final spacing = responsive.value<double>(phone: 8, tablet: 10, kiosk: 12);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < pin.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color ?? ColorSet.light.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isFilled ? dotSize * 0.6 : 0,
                height: isFilled ? dotSize * 0.6 : 0,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color ?? ColorSet.light),
              ),
            ),
          ),
        );
      }),
    );
  }
}
