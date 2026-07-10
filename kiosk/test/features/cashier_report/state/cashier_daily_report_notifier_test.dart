import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_daily_report.dart';
import 'package:pos_app/features/cashier_report/entities/cashier_x_reading.dart';
import 'package:pos_app/features/cashier_report/repositories/cashier_report_repository.dart';
import 'package:pos_app/features/cashier_report/state/cashier_daily_report_notifier.dart';

CashierDailyReport _report() => CashierDailyReport(
  cashierName: 'Kayesha Mae Cabigas',
  terminalName: 'T/M#0003',
  businessDate: '07/10/2026',
  reportGeneratedAt: DateTime(2026, 7, 10, 21, 5),
  grossSales: 10839,
  vatableSales: 9677.69,
  vatAmount: 1161.31,
  vatExemptSales: 0,
  zeroRatedSales: 0,
  netOfTax: 9677.69,
  transactionCount: 73,
  totalQuantity: 106,
  totalCashSales: 8158,
  cashSalesCount: 56,
  salesByProduct: const [
    ProductSalesLine(quantity: 1, productName: 'Add on: Pearl', amount: 15),
    ProductSalesLine(quantity: 2, productName: 'Bottled Water', amount: 98),
  ],
  cashLedger: [
    CashLedgerEntry(time: DateTime(2026, 7, 10, 14, 32), reference: null, amount: 405),
  ],
);

class _FakeCashierReportRepository implements CashierReportRepository {
  _FakeCashierReportRepository(this.report);

  CashierDailyReport report;
  int callCount = 0;

  @override
  Future<CashierDailyReport> getDailyReport() async {
    callCount++;
    return report;
  }

  @override
  Future<CashierXReading> getXReading() async => throw UnimplementedError();
}

class _ThrowingCashierReportRepository implements CashierReportRepository {
  @override
  Future<CashierDailyReport> getDailyReport() async {
    throw Exception('network error');
  }

  @override
  Future<CashierXReading> getXReading() async => throw UnimplementedError();
}

void main() {
  test('load() fetches the report and exposes it as data', () async {
    final repo = _FakeCashierReportRepository(_report());
    final container = ProviderContainer(
      overrides: [cashierReportRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    expect(container.read(cashierDailyReportNotifierProvider).value, isNull);

    await container.read(cashierDailyReportNotifierProvider.notifier).load();

    final state = container.read(cashierDailyReportNotifierProvider);
    expect(state.value?.cashierName, 'Kayesha Mae Cabigas');
    expect(state.value?.salesByProduct.length, 2);
    expect(repo.callCount, 1);
  });

  test('load() surfaces repository errors as AsyncError', () async {
    final container = ProviderContainer(
      overrides: [
        cashierReportRepositoryProvider.overrideWithValue(_ThrowingCashierReportRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashierDailyReportNotifierProvider.notifier).load();

    expect(container.read(cashierDailyReportNotifierProvider).hasError, isTrue);
  });
}
