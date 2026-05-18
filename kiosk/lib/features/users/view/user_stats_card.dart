import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

class UserStatsCard extends StatelessWidget {
  const UserStatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.scale(20)),
      decoration: BoxDecoration(
        color: ColorSet.light,
        borderRadius: BorderRadius.circular(context.responsive.scale(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: context.responsive.scale(10),
            offset: Offset(0, context.responsive.value<double>(kiosk: 2, tablet: 1.5, phone: 1)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive.scale(13)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                context.responsive.value<double>(kiosk: 8, tablet: 6, phone: 4),
              ),
            ),
            child: Icon(icon, color: color, size: context.responsive.scale(25)),
          ),
          SizedBox(width: context.responsive.scale(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsive.scale(24),
                    fontWeight: FontWeight.bold,
                    color: ColorSet.text,
                  ),
                ),
                SizedBox(height: context.responsive.scale(5)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsive.scale(12),
                    color: ColorSet.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
