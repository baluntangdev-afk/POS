import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/csv/report_csv_builder.dart';
import 'package:mobile/core/csv/transaction_export_row.dart';
import 'package:mobile/features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import 'package:mobile/features/reports/entities/report_data.dart';

void main() {
  final sampleTxns = [
    TransactionExportRow(
      id: 1,
      soNumber: 'SO-001-2026-0001',
      cashierName: 'John Doe',
      createdAt: DateTime(2026, 8, 29, 8, 5),
      total: 500.0,
      discount: 0.0,
      status: 'completed',
      type: 'dine_in',
      refundedAmount: 0.0,
      voidReason: null,
      paymentMethods: ['cash'],
    ),
    TransactionExportRow(
      id: 2,
      soNumber: null,
      cashierName: 'John Doe',
      createdAt: DateTime(2026, 8, 29, 9, 0),
      total: 200.0,
      discount: 50.0,
      status: 'voided',
      type: 'take_out',
      refundedAmount: 0.0,
      voidReason: 'Customer cancelled',
      paymentMethods: ['cash', 'card'],
    ),
  ];

  final sampleData = XReadingData(
    id: null,
    cashierName: 'John Doe',
    periodStart: DateTime(2026, 8, 29, 8, 0),
    periodEnd: DateTime(2026, 8, 29, 17, 30),
    generatedAt: DateTime(2026, 8, 29, 17, 35),
    totalSales: 700.0,
    transactionCount: 2,
    voidedCount: 1,
    refundedCount: 0,
    paymentBreakdown: [PaymentBreakdown(method: 'cash', total: 700.0, percentage: 100.0)],
    topProducts: [],
    paymentLedgers: [],
    discounts: [],
    totalDiscounts: 50.0,
    vatableSales: 625.0,
    vatAmount: 75.0,
    vatExemptSales: 0.0,
    averageSale: 350.0,
    highestSale: 500.0,
    lowestSale: 200.0,
    cashCollected: 700.0,
  );

  test('CSV has three sections separated by blank lines', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    final lines = csv.split('\n');
    final blankCount = lines.where((l) => l.trim().isEmpty).length;
    expect(blankCount, greaterThanOrEqualTo(2));
  });

  test('header section contains Report Type row', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Report Type,X-Reading'));
  });

  test('payment breakdown section contains headers and method', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Payment Method,Amount,Count'));
    expect(csv, contains('Cash,700.00,'));
  });

  test('transaction detail rows ordered by ascending date', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    final idx1 = csv.indexOf('SO-001-2026-0001');
    final idx2 = csv.indexOf('#000002');
    expect(idx1, lessThan(idx2));
  });

  test('invoice number falls back to padded id when soNumber is null', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('#000002'));
  });

  test('void reason appears in voided row', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Customer cancelled'));
  });

  test('payment methods are comma-joined within the cell', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Cash, Card'));
  });
}
