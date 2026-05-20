import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

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
    final animationController = useAnimationController(duration: POSAnimation.fast);

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
      end: 0.90,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    final buttonHeight = responsive.value<double>(phone: 56, tablet: 64, kiosk: 76);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        selectedButton.value = buttonIndex;
      },
      onTapUp: (_) {
        selectedButton.value = null;
        onPressed();
      },
      onTapCancel: () => selectedButton.value = null,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, _) => Transform.scale(
          scale: scaleAnimation.value,
          child: AnimatedContainer(
            duration: POSAnimation.fast,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: isSelected ? ColorSet.primary : Colors.white,
              borderRadius: BorderRadius.circular(POSRadius.md),
              border: Border.all(
                color: isSelected ? ColorSet.primary : POSColors.borderDefault,
                width: isSelected ? 0 : 1.5,
              ),
              boxShadow: isSelected ? POSShadow.primaryGlow : POSShadow.card,
            ),
            child: Center(
              child: child ??
                  Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: responsive.value<double>(phone: 22, tablet: 26, kiosk: 30),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : POSColors.textPrimary,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
