import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_daily_report.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_x_reading.dart';
import 'package:pos_app/features/cashier_report/repositories/cashier_report_repository.dart';
import 'package:pos_app/features/cashier_report/state/cashier_x_reading_notifier.dart';
import 'package:pos_app/utils/paginated_data.dart';

CashierXReading _report() => CashierXReading(
  cashierName: 'Juan Dela Cruz',
  terminalName: 'POS-01',
  periodStart: DateTime(2026, 7, 9, 8),
  periodEnd: DateTime(2026, 7, 9, 14),
  reportGeneratedAt: DateTime(2026, 7, 9, 14, 32),
  salesByPaymentMethod: const [NameAmount(name: 'Cash', amount: 100)],
  paymentLedgers: const [],
  totalSales: 100,
  totalTransactions: 1,
  completedTransactions: 1,
  voidedTransactions: 0,
  refundedTransactions: 0,
  discounts: const [],
  totalDiscounts: 0,
  vatSales: 89.29,
  vatAmount: 10.71,
  vatExemptSales: 0,
  cashCollected: 100,
  averageSale: 100,
  highestSale: 100,
  lowestSale: 100,
  totalQuantitySold: 2,
);

class _FakeCashierReportRepository implements CashierReportRepository {
  _FakeCashierReportRepository(this.report);

  CashierXReading report;
  int callCount = 0;
  int closeCallCount = 0;

  @override
  Future<CashierXReading> getXReading() async {
    callCount++;
    return report;
  }

  @override
  Future<CashierDailyReport> getDailyReport() async => throw UnimplementedError();

  @override
  Future<CashierXReading> closeXReading() async {
    closeCallCount++;
    return report;
  }

  @override
  Future<CashierDailyReport> closeDailyReport() async => throw UnimplementedError();

  @override
  Future<PaginatedData<CashierXReadingHistoryItem>> getXReadingHistory({
    required int page,
    required int limit,
  }) async => throw UnimplementedError();

  @override
  Future<PaginatedData<CashierDailyReportHistoryItem>> getDailyReportHistory({
    required int page,
    required int limit,
  }) async => throw UnimplementedError();

  @override
  Future<CashierXReading> getXReadingHistoryDetail(String id) async => throw UnimplementedError();

  @override
  Future<CashierDailyReport> getDailyReportHistoryDetail(String id) async =>
      throw UnimplementedError();
}

class _ThrowingCashierReportRepository implements CashierReportRepository {
  @override
  Future<CashierXReading> getXReading() async {
    throw Exception('network error');
  }

  @override
  Future<CashierDailyReport> getDailyReport() async => throw UnimplementedError();

  @override
  Future<CashierXReading> closeXReading() async => throw UnimplementedError();

  @override
  Future<CashierDailyReport> closeDailyReport() async => throw UnimplementedError();

  @override
  Future<PaginatedData<CashierXReadingHistoryItem>> getXReadingHistory({
    required int page,
    required int limit,
  }) async => throw UnimplementedError();

  @override
  Future<PaginatedData<CashierDailyReportHistoryItem>> getDailyReportHistory({
    required int page,
    required int limit,
  }) async => throw UnimplementedError();

  @override
  Future<CashierXReading> getXReadingHistoryDetail(String id) async => throw UnimplementedError();

  @override
  Future<CashierDailyReport> getDailyReportHistoryDetail(String id) async =>
      throw UnimplementedError();
}

void main() {
  test('load() fetches the report and exposes it as data', () async {
    final repo = _FakeCashierReportRepository(_report());
    final container = ProviderContainer(
      overrides: [cashierReportRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    expect(container.read(cashierXReadingNotifierProvider).value, isNull);

    await container.read(cashierXReadingNotifierProvider.notifier).load();

    final state = container.read(cashierXReadingNotifierProvider);
    expect(state.value?.cashierName, 'Juan Dela Cruz');
    expect(repo.callCount, 1);
  });

  test('load() surfaces repository errors as AsyncError', () async {
    final container = ProviderContainer(
      overrides: [
        cashierReportRepositoryProvider.overrideWithValue(_ThrowingCashierReportRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashierXReadingNotifierProvider.notifier).load();

    expect(container.read(cashierXReadingNotifierProvider).hasError, isTrue);
  });

  test('print() does not close when there are no unreported transactions', () async {
    final emptyReport = CashierXReading(
      cashierName: 'Juan Dela Cruz',
      terminalName: 'POS-01',
      periodStart: null,
      periodEnd: null,
      reportGeneratedAt: DateTime(2026, 7, 9, 14, 32),
      salesByPaymentMethod: const [],
      paymentLedgers: const [],
      totalSales: 0,
      totalTransactions: 0,
      completedTransactions: 0,
      voidedTransactions: 0,
      refundedTransactions: 0,
      discounts: const [],
      totalDiscounts: 0,
      vatSales: 0,
      vatAmount: 0,
      vatExemptSales: 0,
      cashCollected: 0,
      averageSale: 0,
      highestSale: 0,
      lowestSale: 0,
      totalQuantitySold: 0,
    );
    final repo = _FakeCashierReportRepository(emptyReport);
    final container = ProviderContainer(
      overrides: [cashierReportRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(cashierXReadingNotifierProvider.notifier).load();
    await container.read(cashierXReadingNotifierProvider.notifier).print();

    expect(repo.closeCallCount, 0);
  });
}
