import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

const _kChartColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
  AppColors.textSecondary,
];

/// Reusable donut chart for a title + parallel label/value lists.
/// Kept generic (rather than typed to one breakdown entity) so it can be fed
/// by payment/cashier/category breakdowns alike via thin call-site mapping.
class SalesDonutChart extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;

  const SalesDonutChart({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold(0.0, (a, b) => a + b);

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
          Text(
            title,
            style: AppTextStyles.headingSm.copyWith(color: AppColors.textPrimary),
          ),
          const Gap(AppSpacing.md),
          if (total <= 0)
            const _EmptyDonut()
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: List.generate(labels.length, (i) {
                    final value = values[i];
                    final pct = total > 0 ? (value / total * 100) : 0.0;
                    return PieChartSectionData(
                      value: value,
                      color: _kChartColors[i % _kChartColors.length],
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 48,
                      titleStyle: AppTextStyles.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Column(
              children: List.generate(labels.length, (i) {
                final isLast = i == labels.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _kChartColors[i % _kChartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: AppTextStyles.bodySm,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'PHP ${values[i].toStringAsFixed(2)}',
                        style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDonut extends StatelessWidget {
  const _EmptyDonut();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pie_chart_outline_rounded, size: 40, color: AppColors.textDisabled),
            const Gap(AppSpacing.sm),
            Text(
              'No data available',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
