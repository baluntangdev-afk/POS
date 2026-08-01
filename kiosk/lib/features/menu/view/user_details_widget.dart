import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/access.dart';

class UserDetailsWidget extends StatelessWidget {
  const UserDetailsWidget({super.key, required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      margin: responsive.value<EdgeInsets>(
        phone: const EdgeInsets.all(16.0),
        tablet: const EdgeInsets.all(24.0),
        kiosk: const EdgeInsets.all(32.0),
      ),
      padding: responsive.value<EdgeInsets>(
        phone: const EdgeInsets.all(16.0),
        tablet: const EdgeInsets.all(24.0),
        kiosk: const EdgeInsets.all(28.0),
      ),
      decoration: BoxDecoration(
        color: POSColors.surfaceBase,
        borderRadius: BorderRadius.circular(
          responsive.value<double>(phone: 16, tablet: 20, kiosk: 24),
        ),
        boxShadow: POSShadow.card,
        border: Border.all(color: POSColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: responsive.scale(110),
            height: responsive.scale(110),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ColorSet.userDetails,
                  ColorSet.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorSet.userDetails.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Icon(Icons.person, size: responsive.scale(56), color: Colors.white),
            ),
          ),
          SizedBox(width: responsive.value<double>(phone: 16, tablet: 20, kiosk: 24)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorSet.userDetails.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    access.role.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: responsive.scale(11),
                      color: ColorSet.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(height: responsive.value<double>(phone: 6, tablet: 8, kiosk: 10)),
                Text(
                  access.fullName,
                  style: TextStyle(
                    fontSize: responsive.scale(26),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: responsive.value<double>(phone: 2, tablet: 4, kiosk: 4)),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: responsive.scale(14),
                      color: POSColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      access.employeeId,
                      style: TextStyle(
                        fontSize: responsive.scale(16),
                        color: POSColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
