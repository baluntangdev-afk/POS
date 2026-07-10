import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_daily_report.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_x_reading.dart';
import 'package:pos_app/features/cashier_report/repositories/cashier_report_repository.dart';
import 'package:pos_app/features/cashier_report/state/cashier_x_reading_notifier.dart';

CashierXReading _report() => CashierXReading(
  cashierName: 'Juan Dela Cruz',
  terminalName: 'POS-01',
  businessDate: '07/09/2026',
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

  @override
  Future<CashierXReading> getXReading() async {
    callCount++;
    return report;
  }

  @override
  Future<CashierDailyReport> getDailyReport() async => throw UnimplementedError();
}

class _ThrowingCashierReportRepository implements CashierReportRepository {
  @override
  Future<CashierXReading> getXReading() async {
    throw Exception('network error');
  }

  @override
  Future<CashierDailyReport> getDailyReport() async => throw UnimplementedError();
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
}
