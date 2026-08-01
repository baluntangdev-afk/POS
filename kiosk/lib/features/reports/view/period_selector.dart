import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
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
        return [SalesReportPeriod.hourly];

      case DateFilter.thisMonth:
      case DateFilter.lastMonth:
        return [SalesReportPeriod.daily];

      case DateFilter.custom:
        if (customStartDate != null && customEndDate != null) {
          final daysDifference = customEndDate!.difference(customStartDate!).inDays;

          if (daysDifference == 0) {
            return [SalesReportPeriod.hourly];
          } else if (daysDifference <= 31) {
            return [SalesReportPeriod.daily];
          } else {
            return [SalesReportPeriod.monthly];
          }
        }
        return SalesReportPeriod.values;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final availablePeriods = _availablePeriods;

    final effectivePeriod =
        availablePeriods.contains(currentPeriod) ? currentPeriod : availablePeriods.first;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...availablePeriods.map((period) {
            final isSelected = period == effectivePeriod;
            return _PeriodTab(
              label: period.displayName,
              isSelected: isSelected,
              onTap: () => onPeriodChanged(period),
              responsive: r,
            );
          }),
          Gap(r.value<double>(kiosk: 6, tablet: 5, phone: 4)),
          Consumer(
            builder: (context, ref, child) {
              return _DateFilterButton(
                selectedFilter: selectedDateFilter,
                responsive: r,
                onPressed: () {
                  final selectedFilter = ref.watch(
                    salesReportProvider.select((state) => state.selectedDateFilter),
                  );
                  showDialog<void>(
                    context: context,
                    builder: (context) => DateFilterDialog(
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

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.responsive,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ResponsiveValue responsive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(POSRadius.sm),
      child: AnimatedContainer(
        duration: POSAnimation.fast,
        decoration: BoxDecoration(
          color: isSelected ? ColorSet.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(POSRadius.sm),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(POSRadius.sm),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.value<double>(kiosk: 14, tablet: 12, phone: 10),
                vertical: responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : POSColors.textSecondary,
                  fontSize: responsive.value<double>(kiosk: 13, tablet: 12, phone: 11),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.selectedFilter,
    required this.responsive,
    required this.onPressed,
  });

  final DateFilter selectedFilter;
  final ResponsiveValue responsive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorSet.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(POSRadius.sm),
        border: Border.all(color: ColorSet.primary.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(POSRadius.sm),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
              vertical: responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: responsive.value<double>(kiosk: 15, tablet: 14, phone: 13),
                  color: ColorSet.primary,
                ),
                SizedBox(width: responsive.value<double>(kiosk: 6, tablet: 5, phone: 4)),
                Text(
                  selectedFilter.displayName,
                  style: TextStyle(
                    color: ColorSet.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.value<double>(kiosk: 13, tablet: 12, phone: 11),
                  ),
                ),
                SizedBox(width: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2)),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: responsive.value<double>(kiosk: 15, tablet: 14, phone: 13),
                  color: ColorSet.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
