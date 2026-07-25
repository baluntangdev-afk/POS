import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/sales_health_data.dart';
import '../state/reports_notifier.dart';
import '../state/sales_health_notifier.dart';
import 'sales_bar_chart.dart';
import 'sales_donut_chart.dart';

class SalesHealthTab extends HookConsumerWidget {
  const SalesHealthTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() => ref.read(salesHealthProvider.notifier).refresh());
      return null;
    }, const []);

    final state = ref.watch(salesHealthProvider);
    final notifier = ref.read(salesHealthProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: _HealthPeriodSelector(
            selected: notifier.period,
            onChanged: (p) => notifier.setPeriod(p),
            onCustomTap: () => _pickCustomRange(context, ref),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const Gap(AppSpacing.md),
                  Text('Failed to load sales health',
                      style: AppTextStyles.headingSm.copyWith(color: AppColors.textSecondary)),
                  const Gap(AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => notifier.refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (data) => _SalesHealthBody(data: data),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(salesHealthProvider.notifier).setPeriod(ReportPeriod.custom, customRange: picked);
    }
  }
}

class _HealthPeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;
  final VoidCallback onCustomTap;

  const _HealthPeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(label: 'Today', isSelected: selected == ReportPeriod.today, onTap: () => onChanged(ReportPeriod.today)),
          const Gap(AppSpacing.sm),
          _Chip(label: 'This Week', isSelected: selected == ReportPeriod.week, onTap: () => onChanged(ReportPeriod.week)),
          const Gap(AppSpacing.sm),
          _Chip(label: 'This Month', isSelected: selected == ReportPeriod.month, onTap: () => onChanged(ReportPeriod.month)),
          const Gap(AppSpacing.sm),
          _Chip(label: 'Custom', isSelected: selected == ReportPeriod.custom, onTap: onCustomTap, icon: Icons.date_range_rounded),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _Chip({required this.label, required this.isSelected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
              const Gap(4),
            ],
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesHealthBody extends ConsumerWidget {
  final SalesHealthData data;
  const _SalesHealthBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(salesHealthProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _GranularitySelector(
          selected: data.granularity,
          onChanged: (g) => notifier.setGranularity(g),
        ),
        const Gap(AppSpacing.sm),
        SalesBarChart(points: data.timeSeries),
        const Gap(AppSpacing.lg),
        SalesDonutChart(
          title: 'Sales by Payment Method',
          labels: data.paymentBreakdown.map((p) => p.displayName).toList(),
          values: data.paymentBreakdown.map((p) => p.total).toList(),
        ),
        const Gap(AppSpacing.lg),
        SalesDonutChart(
          title: 'Sales by Cashier',
          labels: data.salesByCashier.map((c) => c.cashierName).toList(),
          values: data.salesByCashier.map((c) => c.total).toList(),
        ),
        const Gap(AppSpacing.lg),
        SalesDonutChart(
          title: 'Sales by Category',
          labels: data.salesByCategory.map((c) => c.groupName).toList(),
          values: data.salesByCategory.map((c) => c.total).toList(),
        ),
      ],
    );
  }
}

class _GranularitySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _GranularitySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'Hourly', isSelected: selected == 'hour', onTap: () => onChanged('hour')),
        const Gap(AppSpacing.sm),
        _Chip(label: 'Daily', isSelected: selected == 'day', onTap: () => onChanged('day')),
        const Gap(AppSpacing.sm),
        _Chip(label: 'Monthly', isSelected: selected == 'month', onTap: () => onChanged('month')),
      ],
    );
  }
}
