import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../entities/sales_data_item.dart';
import '../enums/sales_data_item_type.dart';
import '../state/sales_report_notifier.dart';
import '../state/sales_report_state.dart';
import 'period_selector.dart';

class SalesHealthPage extends ConsumerStatefulWidget {
  const SalesHealthPage({super.key});

  @override
  ConsumerState<SalesHealthPage> createState() => _SalesHealthPageState();
}

class _SalesHealthPageState extends ConsumerState<SalesHealthPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final state = ref.watch(salesReportProvider);
    final groupedData = state.groupedSalesData;
    final isLoading = state.isLoading;

    // Use separate health page date filters
    final selectedDateFilter = state.healthPageDateFilter;
    final customStartDate = state.healthPageCustomStartDate;
    final customEndDate = state.healthPageCustomEndDate;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 32),
              child: PeriodSelector(
                currentPeriod: state.healthPagePeriod,
                selectedDateFilter: selectedDateFilter,
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                onPeriodChanged: ref.read(salesReportProvider.notifier).updateHealthPagePeriod,
                onFilterChanged: ref.read(salesReportProvider.notifier).updateHealthPageDateFilter,
                onCustomDateChanged:
                    ref.read(salesReportProvider.notifier).updateHealthPageCustomDateRange,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: responsive.value<EdgeInsets>(
                phone: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                tablet: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                kiosk: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: ResponsiveWrapContainer(
                rowItems: 2,
                spacing: 12,
                items: [
                  _SalesDonutChart(
                    title: 'Sales by Category',
                    data: groupedData[SalesDataItemType.productGroup]?.toList() ?? [],
                    dateRange: _getDateRangeText(
                      selectedDateFilter,
                      customStartDate,
                      customEndDate,
                    ),
                  ),
                  _SalesDonutChart(
                    title: 'Sales by Item',
                    data: groupedData[SalesDataItemType.product]?.toList() ?? [],
                    dateRange: _getDateRangeText(
                      selectedDateFilter,
                      customStartDate,
                      customEndDate,
                    ),
                  ),
                  _SalesDonutChart(
                    title: 'Sales by Cashier',
                    data: groupedData[SalesDataItemType.user]?.toList() ?? [],
                    dateRange: _getDateRangeText(
                      selectedDateFilter,
                      customStartDate,
                      customEndDate,
                    ),
                  ),
                  _SalesDonutChart(
                    title: 'Sales by Payment',
                    data: groupedData[SalesDataItemType.payment]?.toList() ?? [],
                    dateRange: _getDateRangeText(
                      selectedDateFilter,
                      customStartDate,
                      customEndDate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText(DateFilter dateFilter, DateTime? startDate, DateTime? endDate) {
    final period = ref.read(salesReportProvider).healthPagePeriod;
    final includeTime = period == SalesReportPeriod.hourly;

    switch (dateFilter) {
      case DateFilter.today:
        final now = DateTime.now();
        if (includeTime) {
          return '${DateFormat('MMM d, yyyy, 12:00 a').format(DateTime(now.year, now.month, now.day))} - ${DateFormat('MMM d, yyyy, 11:59 a').format(DateTime(now.year, now.month, now.day, 23, 59))}';
        } else {
          return '${DateFormat('MMM d, yyyy').format(DateTime(now.year, now.month, now.day))} - ${DateFormat('MMM d, yyyy').format(DateTime(now.year, now.month, now.day))}';
        }
      case DateFilter.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        if (includeTime) {
          return '${DateFormat('MMM d, yyyy, 12:00 a').format(DateTime(yesterday.year, yesterday.month, yesterday.day))} - ${DateFormat('MMM d, yyyy, 11:59 a').format(DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59))}';
        } else {
          return '${DateFormat('MMM d, yyyy').format(DateTime(yesterday.year, yesterday.month, yesterday.day))} - ${DateFormat('MMM d, yyyy').format(DateTime(yesterday.year, yesterday.month, yesterday.day))}';
        }
      case DateFilter.thisMonth:
        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month);
        final lastDay = DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1));
        if (includeTime) {
          return '${DateFormat('MMM d, yyyy, 12:00 a').format(firstDay)} - ${DateFormat('MMM d, yyyy, 11:59 a').format(lastDay)}';
        } else {
          return '${DateFormat('MMM d, yyyy').format(firstDay)} - ${DateFormat('MMM d, yyyy').format(lastDay)}';
        }
      case DateFilter.lastMonth:
        final lastMonth = DateTime.now().subtract(const Duration(days: 30));
        final firstDay = DateTime(lastMonth.year, lastMonth.month);
        final lastDay = DateTime(
          lastMonth.year,
          lastMonth.month + 1,
        ).subtract(const Duration(milliseconds: 1));
        if (includeTime) {
          return '${DateFormat('MMM d, yyyy, 12:00 a').format(firstDay)} - ${DateFormat('MMM d, yyyy, 11:59 a').format(lastDay)}';
        } else {
          return '${DateFormat('MMM d, yyyy').format(firstDay)} - ${DateFormat('MMM d, yyyy').format(lastDay)}';
        }
      case DateFilter.custom:
        if (startDate != null && endDate != null) {
          if (includeTime) {
            return '${DateFormat('MMM d, yyyy, 12:00 a').format(DateTime(startDate.year, startDate.month, startDate.day))} - ${DateFormat('MMM d, yyyy, 11:59 a').format(DateTime(endDate.year, endDate.month, endDate.day, 23, 59))}';
          } else {
            return '${DateFormat('MMM d, yyyy').format(DateTime(startDate.year, startDate.month, startDate.day))} - ${DateFormat('MMM d, yyyy').format(DateTime(endDate.year, endDate.month, endDate.day))}';
          }
        }
        return 'Custom date range';
    }
  }
}

class _SalesDonutChart extends StatelessWidget {
  const _SalesDonutChart({required this.title, required this.data, required this.dateRange});

  final String title;
  final List<SalesDataItem> data;
  final String dateRange;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    if (data.isEmpty) {
      return _buildEmptyCard(context);
    }

    final totalSales = data.fold<double>(0.0, (sum, item) => sum + item.totalSales);
    final chartData = data.toList();

    return Container(
      height: responsive.value<double>(
        kiosk: 500,
        tablet: 450,
        phone: 400,
      ), // Fixed height to prevent layout issues
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: responsive.scale(25),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2)),
            Text(
              dateRange,
              style: TextStyle(fontSize: responsive.scale(18), color: Colors.grey.shade600),
            ),
            SizedBox(height: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: responsive.value<double>(kiosk: 60, tablet: 55, phone: 50),
                  sections:
                      chartData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final value = item.totalSales;
                        final percentage = (value / totalSales) * 100;

                        return PieChartSectionData(
                          color: _getChartColor(index),
                          value: value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: responsive.value<double>(kiosk: 50, tablet: 45, phone: 40),
                          titleStyle: TextStyle(
                            fontSize: responsive.scale(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            Expanded(child: _buildLegend(context, chartData)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      height: responsive.value<double>(
        kiosk: 300,
        tablet: 280,
        phone: 250,
      ), // Fixed height to prevent layout issues
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: responsive.value<double>(kiosk: 16, tablet: 15, phone: 14),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2)),
            Text(
              dateRange,
              style: TextStyle(
                fontSize: responsive.value<double>(kiosk: 12, tablet: 11, phone: 10),
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart,
                      size: responsive.value<double>(kiosk: 48, tablet: 44, phone: 40),
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: responsive.value<double>(kiosk: 8, tablet: 7, phone: 6)),
                    Text(
                      'No data available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: responsive.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<SalesDataItem> items) {
    final responsive = context.responsive;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: responsive.scale(17),
                    height: responsive.scale(17),
                    decoration: BoxDecoration(color: _getChartColor(index), shape: BoxShape.circle),
                  ),
                  SizedBox(width: responsive.value<double>(kiosk: 8, tablet: 7, phone: 6)),
                  Expanded(
                    child: Text(
                      '${item.name} - P${NumberFormat.decimalPattern().format(item.totalSales)}',
                      style: TextStyle(
                        fontSize: responsive.scale(18),
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      const Color(0xFF06B6D4), // Cyan/Teal
      const Color(0xFF10B981), // Green
      const Color(0xFFF97316), // Orange
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
    ];
    return colors[index % colors.length];
  }
}
