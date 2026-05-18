import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/responsive/responsive_value.dart';
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
    final selectedDateFilter = state.selectedDateFilter;
    final selectedTab = state.selectedTab;

    return WindowsScaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
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
                if (context.canPop()) {
                  context.pop();
                }
              },
              title: 'Sales Report',
            ),
          ),
          Container(
            padding: context.responsive.value<EdgeInsets>(
              phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              kiosk: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            color: Colors.white,
            child: ReportTabSelector(
              selectedTab: selectedTab,
              onTabChanged: (tab) {
                ref.read(salesReportProvider.notifier).updateTab(tab);
              },
            ),
          ),

          // Content with AnimatedSwitcher
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child:
                  selectedTab == ReportTab.dashboard
                      ? _DashboardContent(
                        key: const ValueKey('dashboard'),
                        state: state,
                        selectedDateFilter: selectedDateFilter,
                      )
                      : const SalesHealthPage(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({super.key, required this.state, required this.selectedDateFilter});

  final SalesReportState state;
  final DateFilter selectedDateFilter;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: responsive.value<EdgeInsets>(
          phone: const EdgeInsets.symmetric(horizontal: 20),
          tablet: const EdgeInsets.symmetric(horizontal: 24),
          kiosk: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.scale(33)),
            _MetricsCards(
              state: state,
              columns: responsive.value<int>(kiosk: 3, tablet: 2, phone: 2),
            ),
            SizedBox(height: responsive.scale(45)),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const _SalesChartSection(),
            ),
            SizedBox(height: responsive.scale(45)),
            // _QuickActions(state: state),
          ],
        ),
      ),
    );
  }
}

class _SalesChartSection extends StatelessWidget {
  const _SalesChartSection();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),
        child: const SalesBarChart(),
      ),
    );
  }
}

class _MetricsCards extends StatelessWidget {
  const _MetricsCards({required this.state, required this.columns});

  final SalesReportState state;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final metrics = [
      Metric(
        title: 'Total Net Sales',
        value: state.totalNetSales.toStringAsFixed(2),
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      Metric(
        title: 'Total Refunds',
        value: state.totalRefunds.toStringAsFixed(2),
        icon: Icons.money_off,
        color: Colors.red,
      ),
      Metric(
        title: 'Total Discounts',
        value: state.totalDiscounts.toStringAsFixed(2),
        icon: Icons.local_offer,
        color: Colors.orange,
      ),
      Metric(
        isMonetary: false,
        title: 'No. of Transactions',
        value: state.totalTransactions.toString(),
        icon: Icons.receipt,
        color: Colors.purple,
      ),
      Metric(
        isMonetary: false,
        title: 'No. of Items',
        value: state.totalItems.toString(),
        icon: Icons.inventory_2,
        color: Colors.teal,
      ),
    ];

    return ResponsiveWrapContainer(
      items: metrics.map((metric) => _MetricCard(metric: metric)).toList(),
      rowItems: columns,
      spacing: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = responsive.scale(21);
        final iconSize = responsive.scale(35);
        final titleFontSize = responsive.scale(23);
        final valueFontSize = responsive.scale(27);
        final spacing = responsive.scale(17);

        final value =
            '${metric.isMonetary ? r'P' : ''}${NumberFormat.decimalPattern().format(double.tryParse(metric.value.replaceAll(',', '')) ?? 0)}';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: iconSize),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        metric.title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
