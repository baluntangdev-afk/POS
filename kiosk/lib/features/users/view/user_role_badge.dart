import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({required this.isAdmin, super.key});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isAdmin
                ? ColorSet.secondary.withValues(alpha: 0.1)
                : ColorSet.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          fontSize: context.responsive.scale(16),
          fontWeight: FontWeight.w600,
          color: isAdmin ? ColorSet.secondary : ColorSet.success,
        ),
      ),
    );
  }
}
