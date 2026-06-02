import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/metric.dart';
import '../state/sales_report_notifier.dart';
import '../state/sales_report_state.dart';
import 'report_tab_selector.dart';
import 'sales_bar_chart.dart';
import 'sales_health_page.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesReportProvider);
    final selectedTab = state.selectedTab;
    final isAndroid = context.breakpoint.isAndroid;
    final r = context.responsive;

    Widget content = ColoredBox(
      color: ColorSet.background,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TopAppBar(
                onBackPressed: () {
                  if (context.canPop()) context.pop();
                },
                title: 'Sales Report',
              ),
            ),
            Container(
              color: Colors.white,

              child: Container(
                padding: r.value<EdgeInsets>(
                  phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  kiosk: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: ReportTabSelector(
                  selectedTab: selectedTab,
                  onTabChanged: (tab) =>
                      ref.read(salesReportProvider.notifier).updateTab(tab),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: selectedTab == ReportTab.dashboard
                    ? _DashboardContent(
                        key: const ValueKey('dashboard'),
                        state: state,
                        isAndroid: isAndroid,
                        onRetry: () => ref.invalidate(salesReportProvider),
                      )
                    : const SalesHealthPage(key: ValueKey('health')),
              ),
            ),
          ],
        ),
      ),
    );

    if (isAndroid) {
      content = RefreshIndicator(
        onRefresh: () async => ref.invalidate(salesReportProvider),
        color: ColorSet.primary,
        child: content,
      );
    }

    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: content);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: content);
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    super.key,
    required this.state,
    required this.isAndroid,
    required this.onRetry,
  });

  final SalesReportState state;
  final bool isAndroid;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.error != null && !state.isLoading) {
      return _ReportErrorView(error: state.error!, onRetry: onRetry);
    }

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorSet.primary,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      );
    }

    return isAndroid
        ? _AndroidDashboard(state: state)
        : _WindowsDashboard(state: state);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Windows layout: metrics row on top, chart fills remaining height
// ─────────────────────────────────────────────────────────────────────────────
class _WindowsDashboard extends StatelessWidget {
  const _WindowsDashboard({required this.state});

  final SalesReportState state;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final metrics = _buildMetrics(state);
    final padding = r.value<double>(kiosk: 20, tablet: 16, phone: 12);
    final gap = r.value<double>(kiosk: 12, tablet: 10, phone: 8);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          // ── Top: 5 metric cards in a single row ──
          SizedBox(
            height: r.value<double>(kiosk: 112, tablet: 100, phone: 88),
            child: Row(
              children: [
                for (int i = 0; i < metrics.length; i++) ...[
                  Expanded(child: _MetricCard(metric: metrics[i])),
                  if (i < metrics.length - 1) Gap(gap),
                ],
              ],
            ),
          ),
          Gap(gap),
          // ── Bottom: chart fills all remaining space ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(POSRadius.xl),
                boxShadow: POSShadow.card,
              ),
              padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
              child: const SalesBarChart(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final raw = double.tryParse(metric.value.replaceAll(',', '')) ?? 0.0;
    final displayValue = metric.isMonetary
        ? 'P${NumberFormat.decimalPattern().format(raw)}'
        : NumberFormat.decimalPattern().format(raw);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
        vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(r.value<double>(kiosk: 6, tablet: 5, phone: 5)),
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(POSRadius.sm),
                ),
                child: Icon(
                  metric.icon,
                  color: metric.color,
                  size: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                ),
              ),
              const Gap(6),
              Expanded(
                child: Text(
                  metric.title,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 11, tablet: 11, phone: 10),
                    color: POSColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 22, tablet: 19, phone: 16),
                fontWeight: FontWeight.w800,
                color: POSColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Android layout: scrollable column
// ─────────────────────────────────────────────────────────────────────────────
class _AndroidDashboard extends StatelessWidget {
  const _AndroidDashboard({required this.state});

  final SalesReportState state;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final metrics = _buildMetrics(state);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: r.value<EdgeInsets>(
        phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        kiosk: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: metrics.map((m) => _AndroidMetricCard(metric: m)).toList(),
          ),
          const Gap(16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(POSRadius.xl),
                boxShadow: POSShadow.card,
              ),
              padding: const EdgeInsets.all(12),
              child: const SalesBarChart(),
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }
}

class _AndroidMetricCard extends StatelessWidget {
  const _AndroidMetricCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final raw = double.tryParse(metric.value.replaceAll(',', '')) ?? 0.0;
    final displayValue = metric.isMonetary
        ? 'P${NumberFormat.decimalPattern().format(raw)}'
        : NumberFormat.decimalPattern().format(raw);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(POSRadius.sm),
            ),
            child: Icon(metric.icon, color: metric.color, size: 16),
          ),
          const Gap(8),
          Text(
            metric.title,
            style: const TextStyle(
              fontSize: 11,
              color: POSColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: POSColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared
// ─────────────────────────────────────────────────────────────────────────────
List<Metric> _buildMetrics(SalesReportState state) => [
      Metric(
        title: 'Net Sales',
        value: state.totalNetSales.toStringAsFixed(2),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF10B981),
      ),
      Metric(
        title: 'Items Sold',
        value: state.totalItems.toString(),
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF0EA5E9),
        isMonetary: false,
      ),
      Metric(
        title: 'Transactions',
        value: state.totalTransactions.toString(),
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF8B5CF6),
        isMonetary: false,
      ),
      Metric(
        title: 'Discounts',
        value: state.totalDiscounts.toStringAsFixed(2),
        icon: Icons.local_offer_outlined,
        color: const Color(0xFFF97316),
      ),
      Metric(
        title: 'Refunds',
        value: state.totalRefunds.toStringAsFixed(2),
        icon: Icons.money_off_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

class _ReportErrorView extends StatelessWidget {
  const _ReportErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(r.value<double>(kiosk: 48, tablet: 32, phone: 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r.value<double>(kiosk: 88, tablet: 72, phone: 60),
              height: r.value<double>(kiosk: 88, tablet: 72, phone: 60),
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: ColorSet.danger,
                size: r.value<double>(kiosk: 44, tablet: 36, phone: 30),
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
            Text(
              'Failed to Load Report',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 22, tablet: 18, phone: 16),
                fontWeight: FontWeight.w700,
                color: POSColors.textPrimary,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 15, tablet: 13, phone: 12),
                color: POSColors.textTertiary,
                height: 1.5,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 28, tablet: 24, phone: 20)),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorSet.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: r.value<double>(kiosk: 28, tablet: 22, phone: 18),
                  vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
