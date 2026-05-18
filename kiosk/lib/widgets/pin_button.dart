import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';

class PinButton extends HookWidget {
  const PinButton({
    super.key,
    required this.size,
    required this.onPressed,
    required this.selectedButton,
    required this.buttonIndex,
    this.label,
    this.child,
  });

  final double size;
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
      end: 0.85,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    return Padding(
      padding: responsive.value<EdgeInsets>(
        phone: const EdgeInsets.symmetric(horizontal: 4),
        tablet: const EdgeInsets.symmetric(horizontal: 6),
        kiosk: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: GestureDetector(
        onTapDown: (_) => selectedButton.value = buttonIndex,
        onTapUp: (_) {
          selectedButton.value = null;
          onPressed();
        },
        onTapCancel: () => selectedButton.value = null,
        child: AnimatedBuilder(
          animation: scaleAnimation,
          builder:
              (context, child) => Transform.scale(
                scale: scaleAnimation.value,
                child: Container(
                  width: size * 0.9,
                  height: size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? ColorSet.primary : ColorSet.light.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: ColorSet.dark.withValues(alpha: isSelected ? 0.3 : 0.15),
                        blurRadius: isSelected ? 8 : 12,
                        offset: Offset(0, isSelected ? 2 : 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        this.child ??
                        Text(
                          label ?? '',
                          style: TextStyle(
                            fontSize: responsive.value<double>(phone: 28, tablet: 36, kiosk: 44),
                            fontWeight: FontWeight.w500,
                            color: isSelected ? ColorSet.light : ColorSet.dark,
                          ),
                        ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
