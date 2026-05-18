import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/responsive/responsive_value.dart';
import '../state/sales_report_notifier.dart';
import '../state/sales_report_state.dart';
import 'date_filter_dialog.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.currentPeriod,
    required this.selectedDateFilter,
    this.customStartDate,
    this.customEndDate,
    required this.onPeriodChanged,
    required this.onFilterChanged,
    required this.onCustomDateChanged,
  });

  final SalesReportPeriod currentPeriod;
  final DateFilter selectedDateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final void Function(SalesReportPeriod) onPeriodChanged;
  final void Function(DateFilter) onFilterChanged;
  final void Function(DateTime, DateTime) onCustomDateChanged;

  List<SalesReportPeriod> get _availablePeriods {
    switch (selectedDateFilter) {
      case DateFilter.today:
      case DateFilter.yesterday:
        // For single day, only hourly makes sense
        return [SalesReportPeriod.hourly];

      case DateFilter.thisMonth:
      case DateFilter.lastMonth:
        // For full month, daily and monthly are appropriate
        return [SalesReportPeriod.daily];

      case DateFilter.custom:
        if (customStartDate != null && customEndDate != null) {
          final daysDifference = customEndDate!.difference(customStartDate!).inDays;

          if (daysDifference == 0) {
            // 1 day
            return [SalesReportPeriod.hourly];
          } else if (daysDifference <= 31) {
            // ≤31 days
            return [SalesReportPeriod.daily];
          } else {
            // ≤365 days or >365 days
            return [SalesReportPeriod.monthly];
          }
        }
        // Fallback for incomplete custom range
        return SalesReportPeriod.values;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final availablePeriods = _availablePeriods;

    // Auto-select first available period if current is not available
    final effectivePeriod =
        availablePeriods.contains(currentPeriod) ? currentPeriod : availablePeriods.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(
          responsive.value<double>(kiosk: 10, tablet: 9, phone: 8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          ...availablePeriods.map((period) {
            final isSelected = period == effectivePeriod;
            return GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12),
                  vertical: responsive.value<double>(kiosk: 10, tablet: 9, phone: 8),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
                  ),
                ),
                child: Text(
                  period.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: responsive.scale(18),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          Gap(responsive.value<double>(kiosk: 10, tablet: 8, phone: 6)),
          Consumer(
            builder: (context, ref, child) {
              return _DateFilterButton(
                selectedFilter: selectedDateFilter,
                onPressed: () {
                  final selectedFilter = ref.watch(
                    salesReportProvider.select((state) => state.selectedDateFilter),
                  );
                  showDialog<void>(
                    context: context,
                    builder:
                        (context) => DateFilterDialog(
                          selectedFilter: selectedFilter,
                          onFilterChanged: onFilterChanged,
                          onCustomDateChanged: onCustomDateChanged,
                        ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({required this.selectedFilter, required this.onPressed});

  final DateFilter selectedFilter;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(
          responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
        ),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
          ),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
              vertical: responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: responsive.scale(20), color: Colors.blue.shade700),
                SizedBox(width: responsive.value<double>(kiosk: 6, tablet: 5, phone: 4)),
                Text(
                  selectedFilter.displayName,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.scale(18),
                  ),
                ),
                SizedBox(width: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2)),
                Icon(
                  Icons.arrow_drop_down,
                  size: responsive.scale(20),
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
