import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';

class PinButton extends HookWidget {
  const PinButton({
    super.key,
    required this.onPressed,
    required this.selectedButton,
    required this.buttonIndex,
    this.label,
    this.child,
  });

  final VoidCallback onPressed;
  final String? label;
  final Widget? child;
  final ValueNotifier<int?> selectedButton;
  final int buttonIndex;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isSelected = selectedButton.value == buttonIndex;
    final animationController = useAnimationController(duration: const Duration(milliseconds: 150));

    useEffect(() {
      if (isSelected) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isSelected]);

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    final buttonHeight = responsive.value<double>(phone: 52, tablet: 60, kiosk: 72);

    return GestureDetector(
      onTapDown: (_) => selectedButton.value = buttonIndex,
      onTapUp: (_) {
        selectedButton.value = null;
        onPressed();
      },
      onTapCancel: () => selectedButton.value = null,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, _) => Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: isSelected ? ColorSet.primary : ColorSet.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: this.child ??
                  Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: responsive.value<double>(phone: 20, tablet: 24, kiosk: 28),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? ColorSet.light : ColorSet.dark,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
