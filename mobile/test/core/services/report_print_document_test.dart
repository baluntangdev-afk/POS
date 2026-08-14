import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/receipt_print_document.dart';
import 'package:mobile/core/services/report_print_document.dart';
import 'package:mobile/features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import 'package:mobile/features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import 'package:mobile/features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import 'package:mobile/features/reports/entities/report_data.dart';

XReadingData _xReadingData({
  int? id,
  List<PaymentLedger> paymentLedgers = const [],
  List<NameAmount> discounts = const [],
}) {
  return XReadingData(
    id: id,
    cashierName: 'Jane Cashier',
    periodStart: DateTime(2026, 8, 1, 8),
    periodEnd: DateTime(2026, 8, 1, 17),
    generatedAt: DateTime(2026, 8, 1, 17, 5),
    totalSales: 1000,
    transactionCount: 10,
    voidedCount: 1,
    refundedCount: 0,
    paymentBreakdown: const [PaymentBreakdown(method: 'cash', total: 1000, percentage: 100)],
    topProducts: const [TopProductData(name: 'Burger', quantity: 3, total: 300)],
    paymentLedgers: paymentLedgers,
    discounts: discounts,
    totalDiscounts: 0,
    vatableSales: 892.86,
    vatAmount: 107.14,
    vatExemptSales: 0,
    averageSale: 100,
    highestSale: 200,
    lowestSale: 50,
    cashCollected: 1000,
  );
}

DailyReportData _dailyReportData({int? id}) {
  return DailyReportData(
    id: id,
    cashierName: 'Jane Cashier',
    periodStart: DateTime(2026, 8, 1, 8),
    periodEnd: DateTime(2026, 8, 1, 17),
    generatedAt: DateTime(2026, 8, 1, 17, 5),
    grossSales: 1000,
    vatableSales: 892.86,
    vatAmount: 107.14,
    vatExemptSales: 0,
    netOfTax: 892.86,
    transactionCount: 10,
    totalQtySold: 15,
    cashSalesTotal: 600,
    cashSalesCount: 6,
    salesByProduct: const [TopProductData(name: 'Burger', quantity: 3, total: 300)],
    cashLedger: [
      CashLedgerEntry(time: DateTime(2026, 8, 1, 9, 30), reference: 'REF-1', amount: 100),
    ],
  );
}

ZReadingData _zReadingData() {
  return ZReadingData(
    id: 1,
    zCounter: 42,
    periodStart: DateTime(2026, 8, 1, 8),
    periodEnd: DateTime(2026, 8, 1, 17),
    generatedAt: DateTime(2026, 8, 1, 17, 5),
    closedByName: 'Jane Cashier',
    authorizedByName: 'Manager Mike',
    beginningBalance: 500,
    endingBalance: 1500,
    totalSales: 1000,
    vatableSales: 892.86,
    vatAmount: 107.14,
    vatExemptSales: 0,
    transactionCount: 10,
    completedCount: 9,
    voidedCount: 1,
    refundedCount: 0,
    discountTotal: 0,
    cashCollected: 1000,
    totalQtySold: 15,
    paymentBreakdown: const [PaymentBreakdown(method: 'cash', total: 1000, percentage: 100)],
    paymentLedgers: const [],
    salesByCashier: const [
      CashierSalesBreakdown(cashierName: 'Jane Cashier', total: 1000, transactionCount: 10),
    ],
    discounts: const [],
  );
}

void main() {
  group('XReadingPrintDocument.build', () {
    test('renders title, cashier, sales summary, and totals', () {
      final instructions = XReadingPrintDocument.build(_xReadingData());

      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any((t) => t.text == 'X-READING' && t.bold && t.sizeMultiplier == 2),
        isTrue,
      );
      expect(
        texts.any(
          (t) => t.text == 'Cashier: Jane Cashier' && t.align == PrintAlign.center,
        ),
        isTrue,
      );
      expect(
        texts.any(
          (t) =>
              t.text == 'Period: 2026-08-01 08:00 - 2026-08-01 17:00' &&
              t.align == PrintAlign.center,
        ),
        isTrue,
      );
      expect(
        texts.any(
          (t) => t.text == 'Printed: 2026-08-01 17:05' && t.align == PrintAlign.center,
        ),
        isTrue,
      );

      expect(texts.any((t) => t.text == 'Total Sales'), isTrue);
      expect(
        texts.any((t) => t.text == 'PHP 1000.00' && t.align == PrintAlign.right),
        isTrue,
      );
      expect(texts.any((t) => t.text == 'Transactions'), isTrue);
      expect(
        texts.any((t) => t.text == '10' && t.align == PrintAlign.right),
        isTrue,
      );
    });

    test('omits the reading number line for a live (unclosed) preview', () {
      final instructions = XReadingPrintDocument.build(_xReadingData(id: null));
      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text.startsWith('X-Reading #')), isFalse);
    });

    test('includes the reading number line once closed', () {
      final instructions = XReadingPrintDocument.build(_xReadingData(id: 7));
      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'X-Reading #7'), isTrue);
    });

    test('renders a payment ledger section grouped by date with a total row', () {
      final ledger = PaymentLedger(
        method: 'cash',
        entries: [
          PaymentLedgerEntry(time: DateTime(2026, 8, 1, 9, 30), reference: '1001', amount: 100),
        ],
        total: 100,
        count: 1,
      );
      final instructions = XReadingPrintDocument.build(_xReadingData(paymentLedgers: [ledger]));

      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'CASH LEDGER' && t.bold), isTrue);

      expect(texts.any((t) => t.text == 'Total CASH [1]'), isTrue);
      expect(
        texts.any((t) => t.text == 'PHP 100.00' && t.align == PrintAlign.right),
        isTrue,
      );
    });
  });

  group('DailyReportPrintDocument.build', () {
    test('renders title, gross sales, and cash ledger grouped by day', () {
      final instructions = DailyReportPrintDocument.build(_dailyReportData());

      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any((t) => t.text == 'DAILY REPORT' && t.bold && t.sizeMultiplier == 2),
        isTrue,
      );
      expect(texts.any((t) => t.text == '2026-08-01'), isTrue);
      expect(
        texts.any(
          (t) =>
              t.text == 'Period: 2026-08-01 08:00 - 2026-08-01 17:00' &&
              t.align == PrintAlign.center,
        ),
        isTrue,
      );

      expect(texts.any((t) => t.text == 'Gross Sales'), isTrue);
      expect(
        texts.any((t) => t.text == 'PHP 1000.00' && t.align == PrintAlign.right),
        isTrue,
      );
      expect(texts.any((t) => t.text.startsWith('09:30')), isTrue);
    });
  });

  group('ZReadingPrintDocument.build', () {
    test('renders title, closed/authorized by, grand total, and sales by cashier', () {
      final instructions = ZReadingPrintDocument.build(_zReadingData());

      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any((t) => t.text == 'Z-READING' && t.bold && t.sizeMultiplier == 2),
        isTrue,
      );
      expect(texts.any((t) => t.text == 'Z-Reading #42'), isTrue);
      expect(
        texts.any(
          (t) => t.text == 'Closed by: Jane Cashier' && t.align == PrintAlign.center,
        ),
        isTrue,
      );
      expect(
        texts.any(
          (t) => t.text == 'Authorized by: Manager Mike' && t.align == PrintAlign.center,
        ),
        isTrue,
      );

      expect(texts.any((t) => t.text == 'Beginning Balance'), isTrue);
      expect(
        texts.any((t) => t.text == 'PHP 500.00' && t.align == PrintAlign.right),
        isTrue,
      );
      expect(texts.any((t) => t.text == 'Jane Cashier (10)'), isTrue);
      expect(
        texts.any((t) => t.text == 'PHP 1000.00' && t.align == PrintAlign.right),
        isTrue,
      );
    });
  });
}
