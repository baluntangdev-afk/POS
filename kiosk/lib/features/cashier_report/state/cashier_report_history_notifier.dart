import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/paginated_data.dart';
import '../entities/cashier_daily_report.dart';
import '../entities/cashier_x_reading.dart';
import '../entities/z_reading.dart';
import '../repositories/cashier_report_repository.dart';

final cashierXReadingHistoryNotifierProvider =
AsyncNotifierProvider<CashierXReadingHistoryNotifier,
    PaginatedData<CashierXReadingHistoryItem>>(
  CashierXReadingHistoryNotifier.new,
  name: 'cashierXReadingHistoryNotifierProvider',
);

class CashierXReadingHistoryNotifier
    extends AsyncNotifier<PaginatedData<CashierXReadingHistoryItem>> {
  @override
  Future<PaginatedData<CashierXReadingHistoryItem>> build() async {
    final repository = ref.watch(cashierReportRepositoryProvider);
    return repository.getXReadingHistory(page: 1, limit: 10);
  }

  Future<void> getResults({required int page, required int limit}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cashierReportRepositoryProvider);
      return repository.getXReadingHistory(page: page, limit: limit);
    });
  }
}

final cashierDailyReportHistoryNotifierProvider = AsyncNotifierProvider<
    CashierDailyReportHistoryNotifier,
    PaginatedData<CashierDailyReportHistoryItem>
>(CashierDailyReportHistoryNotifier.new,
    name: 'cashierDailyReportHistoryNotifierProvider');

class CashierDailyReportHistoryNotifier
    extends AsyncNotifier<PaginatedData<CashierDailyReportHistoryItem>> {
  @override
  Future<PaginatedData<CashierDailyReportHistoryItem>> build() async {
    final repository = ref.watch(cashierReportRepositoryProvider);
    return repository.getDailyReportHistory(page: 1, limit: 10);
  }

  Future<void> getResults({required int page, required int limit}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cashierReportRepositoryProvider);
      return repository.getDailyReportHistory(page: page, limit: limit);
    });
  }
}

final cashierXReadingHistoryDetailProvider = FutureProvider.autoDispose.family<
    CashierXReading,
    String>((ref,
    id,) {
  return ref.watch(cashierReportRepositoryProvider).getXReadingHistoryDetail(
      id);
}, name: 'cashierXReadingHistoryDetailProvider');

final cashierDailyReportHistoryDetailProvider = FutureProvider.autoDispose
    .family<CashierDailyReport, String>((ref, id) {
  return ref.watch(cashierReportRepositoryProvider).getDailyReportHistoryDetail(
      id);
}, name: 'cashierDailyReportHistoryDetailProvider');

final zReadingHistoryNotifierProvider =
AsyncNotifierProvider<ZReadingHistoryNotifier,
    PaginatedData<ZReadingHistoryItem>>(
  ZReadingHistoryNotifier.new,
  name: 'zReadingHistoryNotifierProvider',
);

class ZReadingHistoryNotifier
    extends AsyncNotifier<PaginatedData<ZReadingHistoryItem>> {
  @override
  Future<PaginatedData<ZReadingHistoryItem>> build() async {
    final repository = ref.watch(cashierReportRepositoryProvider);
    return repository.getZReadingHistory(page: 1, limit: 10);
  }

  Future<void> getResults({required int page, required int limit}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cashierReportRepositoryProvider);
      return repository.getZReadingHistory(page: page, limit: limit);
    });
  }
}

final zReadingHistoryDetailProvider = FutureProvider.autoDispose.family<
    ZReading,
    String>((ref,
    id,) {
  return ref.watch(cashierReportRepositoryProvider).getZReadingHistoryDetail(
      id);
}, name: 'zReadingHistoryDetailProvider');
