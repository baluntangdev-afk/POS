import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

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
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.all(r.scale(compact ? 14 : 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.scale(compact ? 10 : 12)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(POSRadius.md),
            ),
            child: Icon(icon, color: color, size: r.scale(compact ? 20 : 24)),
          ),
          SizedBox(width: r.scale(12)),
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
                      fontSize: r.scale(compact ? 20 : 24),
                      fontWeight: FontWeight.w800,
                      color: POSColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: r.scale(3)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: r.scale(compact ? 11 : 13),
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
