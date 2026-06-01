import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/sales_report_type.dart';
import '../state/sales_report_notifier.dart';
import '../state/sales_report_state.dart';
import 'period_selector.dart';

class SalesBarChart extends ConsumerWidget {
  const SalesBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final salesReports = ref.watch(salesReportProvider.select((state) => state.salesReports));
    final selectedPeriod = ref.watch(salesReportProvider.select((state) => state.selectedPeriod));
    final selectedDateFilter = ref.watch(
      salesReportProvider.select((state) => state.selectedDateFilter),
    );
    final customStartDate = ref.watch(salesReportProvider.select((state) => state.customStartDate));
    final customEndDate = ref.watch(salesReportProvider.select((state) => state.customEndDate));
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sales by Date',
                    style: TextStyle(
                      fontSize: responsive.scale(20),
                      fontWeight: FontWeight.w700,
                      color: POSColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                    PeriodSelector(
                      currentPeriod: selectedPeriod,
                      selectedDateFilter: selectedDateFilter,
                      customStartDate: customStartDate,
                      customEndDate: customEndDate,
                      onPeriodChanged: ref.read(salesReportProvider.notifier).updatePeriod,
                      onFilterChanged: ref.read(salesReportProvider.notifier).updateDateFilter,
                      onCustomDateChanged:
                          ref.read(salesReportProvider.notifier).updateCustomDateRange,
                    ),
                  ],
                ),
                SizedBox(height: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2)),
                Text(
                  _getDateFilterDisplayText(selectedDateFilter, customStartDate, customEndDate),
                  style: TextStyle(
                    color: POSColors.textTertiary,
                    fontSize: responsive.scale(14),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: responsive.value<double>(kiosk: 20, tablet: 16, phone: 12)),
                if (salesReports.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth <= 800 ? 1000 : constraints.maxWidth,
                          minHeight: constraints.maxHeight.isFinite
                              ? (constraints.maxHeight - 100).clamp(
                                  responsive.value<double>(kiosk: 200, tablet: 180, phone: 160),
                                  double.infinity,
                                )
                              : responsive.value<double>(kiosk: 300, tablet: 250, phone: 200),
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.all(
                              responsive.value<double>(kiosk: 10, tablet: 8, phone: 6),
                            ),
                            child: BarChart(
                              key: ValueKey(
                                '${selectedDateFilter.name}_${selectedPeriod.name}_${salesReports.length}',
                              ),
                              _buildChartData(salesReports.toList(), selectedPeriod),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: responsive.value<double>(kiosk: 48, tablet: 44, phone: 40),
                            color: POSColors.textDisabled,
                          ),
                          SizedBox(
                            height: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
                          ),
                          Text(
                            'No sales data available',
                            style: TextStyle(
                              color: POSColors.textTertiary,
                              fontSize: responsive.scale(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            height: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2),
                          ),
                          Text(
                            'Try adjusting your date filters',
                            style: TextStyle(
                              color: POSColors.textDisabled,
                              fontSize: responsive.scale(13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  String _getDateFilterDisplayText(DateFilter dateFilter, DateTime? startDate, DateTime? endDate) {
    switch (dateFilter) {
      case DateFilter.today:
        return 'Showing results for: ${DateFormat('MMM d, yyyy').format(DateTime.now())}';
      case DateFilter.yesterday:
        return 'Showing results for: ${DateFormat('MMM d, yyyy').format(DateTime.now().subtract(const Duration(days: 1)))}';
      case DateFilter.thisMonth:
        return 'Showing results for the month of ${DateFormat('MMMM').format(DateTime.now())}';
      case DateFilter.lastMonth:
        return 'Showing results for the month of ${DateFormat('MMMM').format(DateTime.now().subtract(const Duration(days: 30)))}';

      case DateFilter.custom:
        if (startDate != null && endDate != null) {
          final startFormat = DateFormat('MMM d, yyyy');
          final endFormat = DateFormat('MMM d, yyyy');
          return '${startFormat.format(startDate)} - ${endFormat.format(endDate)}';
        }
        return 'Custom date range selected';
    }
  }

  double _roundToNearest200(double value) {
    if (value <= 0) return 500.0; // Minimum value of 200
    return ((value / 500).ceil() * 500).toDouble();
  }

  BarChartData _buildChartData(List<SalesReportType> reports, SalesReportPeriod period) {
    final groupedData = _groupDataByPeriod(reports, period);
    final maxSales =
        groupedData.values.isNotEmpty ? groupedData.values.reduce((a, b) => a > b ? a : b) : 0.0;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _roundToNearest200(maxSales),
      backgroundColor: Colors.transparent,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => ColorSet.primary,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final value = rod.toY.round();
            return BarTooltipItem(
              'P${NumberFormat.decimalPattern().format(double.tryParse(value.toString().replaceAll(',', '')) ?? 0)}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            );
          },
        ),
        touchCallback: (event, barTouchResponse) {
          // Handle touch interactions if needed
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _getLabelInterval(groupedData.length, period),
            getTitlesWidget: (value, meta) {
              final labels = _getLabels(groupedData.keys.toList(), period);
              final index = value.toInt();
              if (index >= 0 && index < labels.length) {
                // Only show labels at calculated intervals to prevent overlap
                if (_shouldShowLabel(index, groupedData.length, period)) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        fontSize: 11,
                        color: POSColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const Text('');
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  'P${NumberFormat.compact().format(value)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: POSColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: POSColors.borderSubtle, strokeWidth: 1, dashArray: [5, 5]);
        },
      ),
      borderData: FlBorderData(show: false),
      barGroups:
          groupedData.entries.map((entry) {
            final index = groupedData.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barsSpace: groupedData.length > 10 ? 4.0 : 2.0,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: _getBarColor(index),
                  width: groupedData.length > 10 ? 20 : (groupedData.length > 5 ? 40 : 60),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  borderSide: BorderSide(
                    color: _getBarColor(index).withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Color _getBarColor(int index) {
    const colors = [
      ColorSet.primary,
      ColorSet.tertiary,
      ColorSet.secondary,
      Color(0xFF4DAFC0),
    ];
    return colors[index % colors.length];
  }

  Map<DateTime, double> _groupDataByPeriod(
    List<SalesReportType> reports,
    SalesReportPeriod period,
  ) {
    final groupedData = <DateTime, double>{};

    for (final report in reports) {
      DateTime key;
      switch (period) {
        case SalesReportPeriod.hourly:
          final hour = report.hour;
          final inputFormat = DateFormat('hh:mm a');

          key = DateTime(DateTime.now().year).copyWith(hour: inputFormat.tryParse(hour)?.hour ?? 0);
        case SalesReportPeriod.daily:
          final date = report.date;
          key = DateFormat('MM/dd/yyyy').tryParse(date) ?? DateTime.now();
        case SalesReportPeriod.monthly:
          final year = report.year;
          final month = report.month;
          key = DateFormat('MMMM/yyyy').tryParse('$month/$year') ?? DateTime.now();
      }

      groupedData[key] = (groupedData[key] ?? 0) + report.total;
    }

    return Map.fromEntries(groupedData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  List<String> _getLabels(List<DateTime> dates, SalesReportPeriod period) {
    return dates.map((date) {
      switch (period) {
        case SalesReportPeriod.hourly:
          return '${date.hour}:00';
        case SalesReportPeriod.daily:
          return DateFormat('MMM d').format(date);
        case SalesReportPeriod.monthly:
          return DateFormat('MMM yyyy').format(date);
      }
    }).toList();
  }

  double _getLabelInterval(int dataLength, SalesReportPeriod period) {
    switch (period) {
      case SalesReportPeriod.hourly:
        // For hourly data, show every 2-4 hours depending on data length
        if (dataLength <= 12) return 1;
        if (dataLength <= 24) return 2;
        return 2;
      case SalesReportPeriod.daily:
        // For daily data, show every 2-5 days depending on data length
        if (dataLength <= 7) return 1;
        if (dataLength <= 15) return 2;
        if (dataLength <= 30) return 2;
        return 2;
      case SalesReportPeriod.monthly:
        // For monthly data, show every month
        return 1;
    }
  }

  bool _shouldShowLabel(int index, int dataLength, SalesReportPeriod period) {
    final interval = _getLabelInterval(dataLength, period);
    return index % interval == 0;
  }
}
