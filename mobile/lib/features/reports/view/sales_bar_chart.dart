import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/database/daos/sales_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Sales-over-time bar chart, bucketed by whatever granularity the caller
/// already grouped [points] into (hour/day/month) — this widget just renders.
class SalesBarChart extends StatelessWidget {
  final List<TimeSeriesPoint> points;

  const SalesBarChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales Over Time',
              style: AppTextStyles.headingSm.copyWith(color: AppColors.textPrimary)),
          const Gap(AppSpacing.md),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_outlined, size: 40, color: AppColors.textDisabled),
                    const Gap(AppSpacing.sm),
                    Text('No data available',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                        'PHP ${rod.toY.toStringAsFixed(2)}',
                        AppTextStyles.bodySm.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox.shrink();
                          // Skip labels when there are too many buckets to avoid overlap.
                          final skip = (points.length / 8).ceil().clamp(1, points.length);
                          if (i % skip != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _shortLabel(points[i].bucketLabel),
                              style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textSecondary, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(points.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].total,
                          color: AppColors.primary,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double get _maxY {
    if (points.isEmpty) return 100;
    final max = points.map((p) => p.total).reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 100;
    return max * 1.2;
  }

  String _shortLabel(String bucketLabel) {
    // 'YYYY-MM-DD HH' -> 'HH:00', 'YYYY-MM-DD' -> 'MM/DD', 'YYYY-MM' -> 'MM/YYYY'
    if (bucketLabel.length == 13) {
      return '${bucketLabel.substring(11, 13)}:00';
    }
    if (bucketLabel.length == 10) {
      return '${bucketLabel.substring(5, 7)}/${bucketLabel.substring(8, 10)}';
    }
    if (bucketLabel.length == 7) {
      return '${bucketLabel.substring(5, 7)}/${bucketLabel.substring(0, 4)}';
    }
    return bucketLabel;
  }
}
