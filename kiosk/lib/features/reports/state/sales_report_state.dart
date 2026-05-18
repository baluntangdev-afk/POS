import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

import '../entities/sales_data_item.dart';
import '../entities/sales_report_type.dart';
import '../entities/sales_summary.dart';
import '../enums/sales_data_item_type.dart';

part 'sales_report_state.mapper.dart';

@MappableEnum()
enum SalesReportPeriod {
  hourly,
  daily,
  monthly;

  String get displayName {
    switch (this) {
      case SalesReportPeriod.hourly:
        return 'Hourly';
      case SalesReportPeriod.daily:
        return 'Daily';
      case SalesReportPeriod.monthly:
        return 'Monthly';
    }
  }
}

@MappableEnum()
enum DateFilter {
  today,
  yesterday,
  thisMonth,
  lastMonth,
  custom;

  String get displayName {
    switch (this) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.yesterday:
        return 'Yesterday';
      case DateFilter.thisMonth:
        return 'This Month';
      case DateFilter.lastMonth:
        return 'Last Month';
      case DateFilter.custom:
        return 'Custom';
    }
  }
}

@MappableEnum()
enum ReportTab {
  dashboard(Icons.dashboard),
  salesHealth(Icons.health_and_safety);

  const ReportTab(this.icon);

  final IconData icon;

  String get displayName {
    switch (this) {
      case ReportTab.dashboard:
        return 'Dashboard';
      case ReportTab.salesHealth:
        return 'Sales Health';
    }
  }
}

@MappableClass()
class SalesReportState with SalesReportStateMappable {
  const SalesReportState({
    required this.salesReports,
    required this.isLoading,
    required this.selectedPeriod,
    required this.selectedDateFilter,
    required this.selectedTab,
    required this.salesReportTypes,
    this.customStartDate,
    this.customEndDate,
    this.error,
    this.salesSummary,
    this.groupedSalesData = const {},
    // Separate date filters for SalesHealthPage
    required this.healthPageDateFilter,
    required this.healthPagePeriod,
    this.healthPageCustomStartDate,
    this.healthPageCustomEndDate,
  });

  SalesReportState.initial()
    : salesReports = const IList.empty(),
      isLoading = false,
      selectedPeriod = SalesReportPeriod.daily,
      selectedDateFilter = DateFilter.thisMonth,
      selectedTab = ReportTab.dashboard,
      salesReportTypes = const IList.empty(),
      customStartDate = null,
      customEndDate = null,
      error = null,
      salesSummary = null,
      groupedSalesData = const {},
      // Initialize health page filters
      healthPageDateFilter = DateFilter.thisMonth,
      healthPagePeriod = SalesReportPeriod.daily,
      healthPageCustomStartDate = null,
      healthPageCustomEndDate = null;

  final IList<SalesReportType> salesReports;
  final bool isLoading;
  final SalesReportPeriod selectedPeriod;
  final DateFilter selectedDateFilter;
  final ReportTab selectedTab;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? error;
  final SalesSummary? salesSummary;
  final IList<SalesReportType> salesReportTypes;
  final Map<SalesDataItemType, IList<SalesDataItem>> groupedSalesData;

  // Separate date filters for SalesHealthPage
  final DateFilter healthPageDateFilter;
  final SalesReportPeriod healthPagePeriod;
  final DateTime? healthPageCustomStartDate;
  final DateTime? healthPageCustomEndDate;

  // Calculate totals from the filtered reports or use sales summary data
  double get totalNetSales {
    final result =
        salesSummary?.totalSales ??
        (salesReports.isEmpty ? 0.0 : salesReports.map((r) => r.total).reduce((a, b) => a + b));
    return result;
  }

  double get totalRefunds {
    final result =
        salesSummary?.totalRefunds ??
        (salesReports.isEmpty
            ? 0.0
            : salesReports.map((r) => r.total).reduce((a, b) => a + b) * 0.1);
    return result;
  }

  double get totalDiscounts {
    final result =
        salesSummary?.totalDiscount ??
        (salesReports.isEmpty ? 0.0 : salesReports.map((r) => r.discount).reduce((a, b) => a + b));
    return result;
  }

  int get totalTransactions {
    final result =
        salesSummary?.totalTransactions ??
        (salesReports.isEmpty
            ? 0
            : salesReports.map((r) => r.transactions).reduce((a, b) => a + b));
    return result;
  }

  int get totalItems {
    final result =
        salesSummary?.totalItems ??
        (salesReports.isEmpty ? 0 : salesReports.map((r) => r.items).reduce((a, b) => a + b));
    return result;
  }
}
