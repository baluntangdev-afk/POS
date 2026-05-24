import 'package:flutter/material.dart';

import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

class UserStatsCard extends StatelessWidget {
  const UserStatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.all(r.value<double>(kiosk: 18, tablet: 14, phone: 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.value<double>(kiosk: 12, tablet: 10, phone: 10)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(POSRadius.md),
            ),
            child: Icon(icon, color: color, size: r.value<double>(kiosk: 24, tablet: 20, phone: 20)),
          ),
          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 24, tablet: 20, phone: 18),
                      fontWeight: FontWeight.w800,
                      color: POSColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 13),
                    color: POSColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
