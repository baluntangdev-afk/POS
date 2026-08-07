import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Filled/empty dot row showing PIN entry progress. Shared by every screen
/// that collects a PIN (login, change-PIN) so the input feels identical.
class PinDots extends StatelessWidget {
  final int length;
  final int total;

  const PinDots({super.key, required this.length, this.total = 6});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final filled = i < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: filled ? 18 : 16,
          height: filled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.divider,
          ),
        );
      }),
    );
  }
}
