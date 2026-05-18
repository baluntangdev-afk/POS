import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
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
        kiosk: const EdgeInsets.all(32.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value<double>(phone: 12, tablet: 16, kiosk: 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: responsive.scale(110),
            height: responsive.scale(110),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: ColorSet.userDetails),
            child: ClipOval(
              child: Icon(Icons.person, size: responsive.scale(60), color: Colors.white),
            ),
          ),
          SizedBox(width: responsive.value<double>(phone: 16, tablet: 20, kiosk: 24)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  access.role.title,
                  style: TextStyle(
                    fontSize: responsive.scale(14),
                    color: ColorSet.userDetails,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: responsive.value<double>(phone: 4, tablet: 6, kiosk: 8)),
                Text(
                  access.fullName,
                  style: TextStyle(
                    fontSize: responsive.scale(28),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: responsive.value<double>(phone: 2, tablet: 4, kiosk: 6)),
                Text(
                  access.employeeId,
                  style: TextStyle(fontSize: responsive.scale(18), color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
