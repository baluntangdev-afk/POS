import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/report_export_service.dart';
import '../entities/report_data.dart';
import '../state/reports_notifier.dart';
import 'sales_health_tab.dart';

class ReportsScreen extends HookConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() => ref.read(reportsProvider.notifier).refresh());
      return null;
    }, const []);

    final reportState = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);
    final isExporting = useState(false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Reports'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: isExporting.value
                  ? null
                  : () => _export(context, reportState.value, isExporting),
              icon: isExporting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              tooltip: 'Export CSV',
            ),
            IconButton(
              onPressed: () => notifier.refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Sales Health'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period selector
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: _PeriodSelector(
                    selected: notifier.period,
                    onChanged: (p) => notifier.setPeriod(p),
                    onCustomTap: () => _pickCustomRange(context, ref),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: reportState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const Gap(AppSpacing.md),
                          Text('Failed to load reports',
                              style: AppTextStyles.headingSm
                                  .copyWith(color: AppColors.textSecondary)),
                          const Gap(AppSpacing.md),
                          FilledButton.icon(
                            onPressed: () => notifier.refresh(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (data) => _ReportBody(data: data),
                  ),
                ),
              ],
            ),
            const SalesHealthTab(),
          ],
        ),
      ),
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
      ref
          .read(reportsProvider.notifier)
          .setPeriod(ReportPeriod.custom, customRange: picked);
    }
  }

  Future<void> _export(
    BuildContext context,
    ReportData? report,
    ValueNotifier<bool> isExporting,
  ) async {
    if (report == null) return;
    isExporting.value = true;
    try {
      final path = await ReportExportService.exportToCsv(report);
      await ReportExportService.shareCsv(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      isExporting.value = false;
    }
  }
}

class _PeriodSelector extends ConsumerWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;
  final VoidCallback onCustomTap;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodChip(
            label: 'Today',
            isSelected: selected == ReportPeriod.today,
            onTap: () => onChanged(ReportPeriod.today),
          ),
          const Gap(AppSpacing.sm),
          _PeriodChip(
            label: 'This Week',
            isSelected: selected == ReportPeriod.week,
            onTap: () => onChanged(ReportPeriod.week),
          ),
          const Gap(AppSpacing.sm),
          _PeriodChip(
            label: 'This Month',
            isSelected: selected == ReportPeriod.month,
            onTap: () => onChanged(ReportPeriod.month),
          ),
          const Gap(AppSpacing.sm),
          _PeriodChip(
            label: 'Custom',
            isSelected: selected == ReportPeriod.custom,
            onTap: onCustomTap,
            icon: Icons.date_range_rounded,
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary),
              const Gap(4),
            ],
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final ReportData data;
  const _ReportBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary cards
        _SummaryCards(data: data),
        const Gap(AppSpacing.lg),

        // Payment breakdown
        if (data.paymentBreakdown.isNotEmpty) ...[
          _SectionHeader('Payment Breakdown'),
          const Gap(AppSpacing.sm),
          _PaymentBreakdownCard(breakdown: data.paymentBreakdown),
          const Gap(AppSpacing.lg),
        ],

        // Top products
        if (data.topProducts.isNotEmpty) ...[
          _SectionHeader('Top Products'),
          const Gap(AppSpacing.sm),
          _TopProductsCard(products: data.topProducts),
          const Gap(AppSpacing.lg),
        ],

        // Recent transactions
        if (data.recentSales.isNotEmpty) ...[
          _SectionHeader('Recent Transactions'),
          const Gap(AppSpacing.sm),
          _TransactionsCard(sales: data.recentSales),
        ],

        if (data.transactionCount == 0)
          _EmptyReport(from: data.from, to: data.to),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.labelMd.copyWith(
          color: AppColors.textSecondary, letterSpacing: 0.8),
    );
  }
}

// ── Summary cards ──────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final ReportData data;
  const _SummaryCards({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 600;
      return wide
          ? Row(
              children: [
                Expanded(child: _MetricCard(label: 'Total Sales', value: 'PHP ${data.totalSales.toStringAsFixed(2)}', icon: Icons.monetization_on_rounded, iconColor: AppColors.primary)),
                const Gap(AppSpacing.md),
                Expanded(child: _MetricCard(label: 'Transactions', value: '${data.transactionCount}', icon: Icons.receipt_long_rounded, iconColor: AppColors.success)),
                const Gap(AppSpacing.md),
                Expanded(child: _MetricCard(label: 'Average Order', value: 'PHP ${data.averageOrder.toStringAsFixed(2)}', icon: Icons.trending_up_rounded, iconColor: AppColors.warning)),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _MetricCard(label: 'Total Sales', value: 'PHP ${data.totalSales.toStringAsFixed(2)}', icon: Icons.monetization_on_rounded, iconColor: AppColors.primary)),
                    const Gap(AppSpacing.md),
                    Expanded(child: _MetricCard(label: 'Transactions', value: '${data.transactionCount}', icon: Icons.receipt_long_rounded, iconColor: AppColors.success)),
                  ],
                ),
                const Gap(AppSpacing.md),
                _MetricCard(label: 'Average Order', value: 'PHP ${data.averageOrder.toStringAsFixed(2)}', icon: Icons.trending_up_rounded, iconColor: AppColors.warning),
              ],
            );
    });
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Gap(AppSpacing.md),
          Text(label,
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary)),
          const Gap(2),
          Text(value,
              style: AppTextStyles.headingMd
                  .copyWith(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Payment breakdown ──────────────────────────────────────────────────────────

class _PaymentBreakdownCard extends StatelessWidget {
  final List<PaymentBreakdown> breakdown;
  const _PaymentBreakdownCard({required this.breakdown});

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
        children: breakdown.map((b) {
          final color = switch (b.method) {
            'cash' => AppColors.success,
            'card' => AppColors.primary,
            'ewallet' => AppColors.warning,
            _ => AppColors.textSecondary,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const Gap(AppSpacing.sm),
                    Text(b.displayName,
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      'PHP ${b.total.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Gap(AppSpacing.sm),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${b.percentage.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: b.percentage / 100,
                    backgroundColor: AppColors.surfaceVariant,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Top products ───────────────────────────────────────────────────────────────

class _TopProductsCard extends StatelessWidget {
  final List<TopProductData> products;
  const _TopProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        products.isEmpty ? 1.0 : products.first.total.clamp(1.0, double.infinity);
    return Container(
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
        children: products.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isLast = i == products.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: i == 0
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                      const Gap(2),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        child: LinearProgressIndicator(
                          value: p.total / maxAmount,
                          backgroundColor: AppColors.surfaceVariant,
                          color: AppColors.primary.withValues(
                              alpha: 0.4 + (0.6 * (1 - i / products.length))),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PHP ${p.total.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('${p.quantity} sold',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Transactions list ──────────────────────────────────────────────────────────

class _TransactionsCard extends StatelessWidget {
  final List<dynamic> sales;
  const _TransactionsCard({required this.sales});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: sales.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isLast = i == sales.length - 1;
          final createdAt = s.createdAt as DateTime;
          final type = s.type as String;
          final total = s.total as double;

          final displayType = switch (type) {
            'dine_in' => 'Dine In',
            'take_out' => 'Take Out',
            'delivery' => 'Delivery',
            _ => type,
          };

          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${(s.id as int).toString().padLeft(6, '0')}',
                      style: AppTextStyles.labelLg
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatTime(createdAt),
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(displayType,
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primary, fontSize: 10)),
                ),
                const Spacer(),
                Text('PHP ${total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyReport extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  const _EmptyReport({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Icon(Icons.bar_chart_outlined,
                  size: 32, color: AppColors.textDisabled),
            ),
            const Gap(AppSpacing.md),
            Text('No sales in this period',
                style: AppTextStyles.headingSm
                    .copyWith(color: AppColors.textSecondary)),
            const Gap(4),
            Text('Complete some orders to see your reports',
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.textDisabled)),
          ],
        ),
      ),
    );
  }
}
