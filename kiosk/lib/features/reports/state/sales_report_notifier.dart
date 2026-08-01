import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../entities/sales_data_item.dart';
import '../enums/sales_data_item_type.dart';
import '../repositories/reports_repository.dart';
import 'sales_report_state.dart';

final salesReportProvider = NotifierProvider.autoDispose(
  SalesReportNotifier.new,
  name: 'salesReportProvider',
);

class SalesReportNotifier extends Notifier<SalesReportState> {
  @override
  SalesReportState build() {
    // Start with loading state
    final initialState = SalesReportState.initial();

    // Load data asynchronously after the state is initialized
    Future.microtask(() {
      _loadSalesData();
      loadGroupedSalesData();
    });

    return initialState;
  }

  Future<void> _loadSalesData() async {
    try {
      state = state.copyWith(isLoading: true);

      // Load sales summary from repository
      final repository = ref.read<ReportsRepository>(reportsRepositoryProvider);
      final startDate = _getStartDate();
      final endDate = _getEndDate();

      final salesSummary = await repository.getSalesReports(startDate: startDate, endDate: endDate);

      // Load sales report type data from repository
      final salesReportTypes = await repository.getSalesReportType(
        type: state.selectedPeriod,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        salesSummary: salesSummary,
        salesReportTypes: salesReportTypes,
        isLoading: false,
      );

      final convertedReports =
          salesReportTypes.map((type) {
            return type;
          }).toIList();
      state = state.copyWith(salesReports: convertedReports);
    } catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (state.selectedDateFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.yesterday:
        return DateTime(now.year, now.month, now.day - 1);
      case DateFilter.thisMonth:
        return DateTime(now.year, now.month);
      case DateFilter.lastMonth:
        return DateTime(now.year, now.month - 1);
      case DateFilter.custom:
        return state.customStartDate ?? DateTime(now.year, now.month);
    }
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    switch (state.selectedDateFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateFilter.yesterday:
        return DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
      case DateFilter.thisMonth:
        return DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1));
      case DateFilter.lastMonth:
        return DateTime(now.year, now.month).subtract(const Duration(milliseconds: 1));
      case DateFilter.custom:
        return state.customEndDate ?? DateTime.now();
    }
  }

  void updatePeriod(SalesReportPeriod period) {
    state = state.copyWith(selectedPeriod: period);
    _loadSalesData(); // Reload both summary and detailed data
  }

  void updateDateFilter(DateFilter filter) {
    final newPeriod = _appropriatePeriodForFilter(filter);
    state = state.copyWith(selectedDateFilter: filter, selectedPeriod: newPeriod);
    _loadSalesData(); // Reload both summary and detailed data
  }

  SalesReportPeriod _appropriatePeriodForFilter(DateFilter filter) {
    switch (filter) {
      case DateFilter.today:
      case DateFilter.yesterday:
        return SalesReportPeriod.hourly;
      case DateFilter.thisMonth:
      case DateFilter.lastMonth:
        return SalesReportPeriod.daily;
      case DateFilter.custom:
        return state.selectedPeriod;
    }
  }

  void updateCustomDateRange(DateTime startDate, DateTime endDate) {
    final daysDifference = endDate.difference(startDate).inDays;
    SalesReportPeriod newPeriod;
    if (daysDifference == 0) {
      newPeriod = SalesReportPeriod.hourly;
    } else if (daysDifference <= 31) {
      newPeriod = SalesReportPeriod.daily;
    } else {
      newPeriod = SalesReportPeriod.monthly;
    }

    state = state.copyWith(
      selectedDateFilter: DateFilter.custom,
      customStartDate: startDate,
      customEndDate: endDate,
      selectedPeriod: newPeriod,
    );
    _loadSalesData(); // Reload both summary and detailed data
  }

  void updateTab(ReportTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void refresh() {
    _loadSalesData();
  }

  Future<void> loadGroupedSalesData() async {
    try {
      state = state.copyWith(isLoading: true);

      final repository = ref.read<ReportsRepository>(reportsRepositoryProvider);
      final startDate = _getHealthPageStartDate();
      final endDate = _getHealthPageEndDate();
      final result = <SalesDataItem>[];

      final futures = await Future.wait([
        repository.getSalesByProductGroups(startDate: startDate, endDate: endDate),
        repository.getSalesByProducts(startDate: startDate, endDate: endDate),
        repository.getSalesByUser(startDate: startDate, endDate: endDate),
        repository.getSalesByPayment(startDate: startDate, endDate: endDate),
      ]);

      futures.forEach(result.addAll);
      final groupedResult = <SalesDataItemType, IList<SalesDataItem>>{};
      for (final item in result) {
        groupedResult.putIfAbsent(item.type, () => const IList.empty());
        groupedResult[item.type] = groupedResult[item.type]!.add(item);
      }
      state = state.copyWith(groupedSalesData: groupedResult, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    }
  }

  // Health page specific methods
  DateTime _getHealthPageStartDate() {
    final now = DateTime.now();
    switch (state.healthPageDateFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.yesterday:
        return DateTime(now.year, now.month, now.day - 1);
      case DateFilter.thisMonth:
        return DateTime(now.year, now.month);
      case DateFilter.lastMonth:
        return DateTime(now.year, now.month - 1);
      case DateFilter.custom:
        return state.healthPageCustomStartDate ?? DateTime(now.year, now.month);
    }
  }

  DateTime _getHealthPageEndDate() {
    final now = DateTime.now();
    switch (state.healthPageDateFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateFilter.yesterday:
        return DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
      case DateFilter.thisMonth:
        return DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1));
      case DateFilter.lastMonth:
        return DateTime(now.year, now.month).subtract(const Duration(milliseconds: 1));
      case DateFilter.custom:
        return state.healthPageCustomEndDate ?? DateTime.now();
    }
  }

  void updateHealthPagePeriod(SalesReportPeriod period) {
    state = state.copyWith(healthPagePeriod: period);
    loadGroupedSalesData();
  }

  void updateHealthPageDateFilter(DateFilter filter) {
    final newPeriod = _appropriatePeriodForHealthPageFilter(filter);
    state = state.copyWith(healthPageDateFilter: filter, healthPagePeriod: newPeriod);
    loadGroupedSalesData();
  }

  SalesReportPeriod _appropriatePeriodForHealthPageFilter(DateFilter filter) {
    switch (filter) {
      case DateFilter.today:
      case DateFilter.yesterday:
        return SalesReportPeriod.hourly;
      case DateFilter.thisMonth:
      case DateFilter.lastMonth:
        return SalesReportPeriod.daily;
      case DateFilter.custom:
        return state.healthPagePeriod;
    }
  }

  void updateHealthPageCustomDateRange(DateTime startDate, DateTime endDate) {
    final daysDifference = endDate.difference(startDate).inDays;
    SalesReportPeriod newPeriod;
    if (daysDifference == 0) {
      newPeriod = SalesReportPeriod.hourly;
    } else if (daysDifference <= 31) {
      newPeriod = SalesReportPeriod.daily;
    } else {
      newPeriod = SalesReportPeriod.monthly;
    }

    state = state.copyWith(
      healthPageDateFilter: DateFilter.custom,
      healthPageCustomStartDate: startDate,
      healthPageCustomEndDate: endDate,
      healthPagePeriod: newPeriod,
    );
    loadGroupedSalesData();
  }
}
