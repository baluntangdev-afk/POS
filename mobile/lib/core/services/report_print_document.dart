import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/reports/entities/report_data.dart';
import 'receipt_print_document.dart';

/// Builds the cashier-accounting reports (X-Reading, Daily Report, Z-Reading)
/// as [PrintInstruction] documents — the same document type [ReceiptPrintDocument]
/// produces — so [PrintService] can dispatch them through the built-in printer
/// or Bluetooth without any report-specific printing code.
abstract final class XReadingPrintDocument {
  static List<PrintInstruction> build(XReadingData data,
      {String currency = 'PHP'}) {
    final instructions = <PrintInstruction>[];

    instructions.add(
      const PrintText(
          'X-READING', align: PrintAlign.center, bold: true, sizeMultiplier: 2),
    );
    instructions.add(const PrintFeed(1));
    if (data.id != null) {
      instructions.add(
          PrintText('X-Reading #${data.id}', align: PrintAlign.center));
    }
    instructions.add(const PrintDivider());
    instructions.add(
        PrintText('Cashier: ${data.cashierName}', align: PrintAlign.center));
    _addPeriodLines(
        instructions, data.periodStart, data.periodEnd, data.generatedAt);

    _sectionHeader(instructions, 'SALES SUMMARY');
    _amountRow(
        instructions, 'Total Sales', data.totalSales, currency: currency);
    _countRow(instructions, 'Transactions', data.transactionCount);

    if (data.paymentBreakdown.isNotEmpty) {
      _sectionHeader(instructions, 'PAYMENT BREAKDOWN');
      for (final p in data.paymentBreakdown) {
        _amountRow(instructions, p.displayName, p.total, currency: currency);
      }
    }

    for (final ledger in data.paymentLedgers) {
      _paymentLedgerInstructions(instructions, ledger, currency: currency);
    }

    if (data.topProducts.isNotEmpty) {
      _sectionHeader(instructions, 'TOP PRODUCTS');
      for (final p in data.topProducts) {
        _amountRow(instructions, '${p.name} x${p.quantity}', p.total,
            currency: currency);
      }
    }

    _sectionHeader(instructions, 'TRANSACTION SUMMARY');
    _countRow(instructions, 'Completed', data.transactionCount);
    _countRow(instructions, 'Voided', data.voidedCount);
    _countRow(instructions, 'Refunded', data.refundedCount);

    _sectionHeader(instructions, 'DISCOUNT SUMMARY');
    for (final d in data.discounts) {
      _amountRow(instructions, d.name, d.amount, currency: currency);
    }
    _amountRow(instructions, 'Total Discounts', data.totalDiscounts,
        currency: currency);

    _sectionHeader(instructions, 'TAX SUMMARY');
    _amountRow(
        instructions, 'VAT Sales', data.vatableSales, currency: currency);
    _amountRow(instructions, 'VAT Amount', data.vatAmount, currency: currency);
    _amountRow(instructions, 'VAT-Exempt Sales', data.vatExemptSales,
        currency: currency);

    _sectionHeader(instructions, 'CASH COLLECTED');
    _amountRow(
        instructions, 'Cash Collected', data.cashCollected, currency: currency);

    _sectionHeader(instructions, 'OTHER SUMMARY');
    _amountRow(
        instructions, 'Average Sale', data.averageSale, currency: currency);
    _amountRow(
        instructions, 'Highest Sale', data.highestSale, currency: currency);
    _amountRow(
        instructions, 'Lowest Sale', data.lowestSale, currency: currency);

    instructions.add(const PrintDivider());
    instructions.add(const PrintFeed(3));

    return instructions;
  }
}

abstract final class DailyReportPrintDocument {
  static List<PrintInstruction> build(DailyReportData data,
      {String currency = 'PHP'}) {
    final instructions = <PrintInstruction>[];

    instructions.add(
      const PrintText('DAILY REPORT', align: PrintAlign.center,
          bold: true,
          sizeMultiplier: 2),
    );
    instructions.add(const PrintFeed(1));
    if (data.id != null) {
      instructions.add(
          PrintText('Daily Report #${data.id}', align: PrintAlign.center));
    }
    instructions.add(const PrintDivider());
    instructions.add(
        PrintText('Cashier: ${data.cashierName}', align: PrintAlign.center));
    _addPeriodLines(
        instructions, data.periodStart, data.periodEnd, data.generatedAt);

    _sectionHeader(instructions, 'GROSS SALES');
    _amountRow(
        instructions, 'Gross Sales', data.grossSales, currency: currency);

    _sectionHeader(instructions, 'VAT SUMMARY');
    _amountRow(
        instructions, 'Vatable Sales', data.vatableSales, currency: currency);
    _amountRow(instructions, 'VAT Amount', data.vatAmount, currency: currency);
    _amountRow(instructions, 'VAT-Exempt Sales', data.vatExemptSales,
        currency: currency);

    _sectionHeader(instructions, 'OTHERS');
    _amountRow(instructions, 'Net of Tax', data.netOfTax, currency: currency);
    _countRow(instructions, 'Transactions', data.transactionCount);
    _countRow(instructions, 'Total Qty Sold', data.totalQtySold);

    _sectionHeader(instructions, 'CASH SALES');
    _amountRow(instructions, 'Cash Sales Total', data.cashSalesTotal,
        currency: currency);
    _countRow(instructions, 'Cash Sales Count', data.cashSalesCount);

    if (data.salesByProduct.isNotEmpty) {
      _sectionHeader(instructions, 'SALES BY PRODUCT');
      for (final p in data.salesByProduct) {
        _amountRow(instructions, '${p.name} x${p.quantity}', p.total,
            currency: currency);
      }
    }

    if (data.cashLedger.isNotEmpty) {
      _sectionHeader(instructions, 'CASH LEDGER');
      for (final group in data.cashLedgerSummariesByDate) {
        instructions.add(PrintText(_fmtDay(group.date), bold: true));
        for (final entry in group.entries) {
          _amountRow(
            instructions,
            '${_fmtTime(entry.time)}${entry.reference != null ? ' #${entry
                .reference}' : ''}',
            entry.amount,
            currency: currency,
          );
        }
        _amountRow(instructions, 'Total', group.total, currency: currency);
      }
    }

    instructions.add(const PrintDivider());
    instructions.add(const PrintFeed(3));

    return instructions;
  }
}

abstract final class ZReadingPrintDocument {
  static List<PrintInstruction> build(ZReadingData data,
      {String currency = 'PHP'}) {
    final instructions = <PrintInstruction>[];

    instructions.add(
      const PrintText(
          'Z-READING', align: PrintAlign.center, bold: true, sizeMultiplier: 2),
    );
    instructions.add(const PrintFeed(1));
    instructions.add(
        PrintText('Z-Reading #${data.zCounter}', align: PrintAlign.center));
    instructions.add(const PrintDivider());
    instructions.add(
        PrintText('Closed by: ${data.closedByName}', align: PrintAlign.center));
    instructions.add(
      PrintText(
          'Authorized by: ${data.authorizedByName}', align: PrintAlign.center),
    );
    _addPeriodLines(
        instructions, data.periodStart, data.periodEnd, data.generatedAt);

    _sectionHeader(instructions, 'GRAND TOTAL');
    _amountRow(instructions, 'Beginning Balance', data.beginningBalance,
        currency: currency);
    _amountRow(
        instructions, 'Ending Balance', data.endingBalance, currency: currency);

    _sectionHeader(instructions, 'SALES SUMMARY');
    _amountRow(
        instructions, 'Total Sales', data.totalSales, currency: currency);
    _countRow(instructions, 'Transactions', data.transactionCount);

    if (data.paymentBreakdown.isNotEmpty) {
      _sectionHeader(instructions, 'PAYMENT BREAKDOWN');
      for (final p in data.paymentBreakdown) {
        _amountRow(instructions, p.displayName, p.total, currency: currency);
      }
    }

    for (final ledger in data.paymentLedgers) {
      _paymentLedgerInstructions(instructions, ledger, currency: currency);
    }

    _sectionHeader(instructions, 'TRANSACTION SUMMARY');
    _countRow(instructions, 'Completed', data.completedCount);
    _countRow(instructions, 'Voided', data.voidedCount);
    _countRow(instructions, 'Refunded', data.refundedCount);

    _sectionHeader(instructions, 'DISCOUNT SUMMARY');
    for (final d in data.discounts) {
      _amountRow(instructions, d.name, d.amount, currency: currency);
    }
    _amountRow(instructions, 'Total Discounts', data.discountTotal,
        currency: currency);

    _sectionHeader(instructions, 'TAX SUMMARY (VAT)');
    _amountRow(
        instructions, 'Vatable Sales', data.vatableSales, currency: currency);
    _amountRow(instructions, 'VAT Amount', data.vatAmount, currency: currency);
    _amountRow(instructions, 'VAT-Exempt Sales', data.vatExemptSales,
        currency: currency);

    _sectionHeader(instructions, 'CASH COLLECTED');
    _amountRow(
        instructions, 'Cash Collected', data.cashCollected, currency: currency);
    _countRow(instructions, 'Total Qty Sold', data.totalQtySold);

    if (data.salesByCashier.isNotEmpty) {
      _sectionHeader(instructions, 'SALES BY CASHIER');
      for (final c in data.salesByCashier) {
        _amountRow(
          instructions,
          '${c.cashierName} (${c.transactionCount})',
          c.total,
          currency: currency,
        );
      }
    }

    instructions.add(const PrintDivider());
    instructions.add(const PrintFeed(3));

    return instructions;
  }
}

// ─── Shared instruction-building helpers for cashier-accounting reports ────

/// Centered period + printed-at lines, mirroring the centered document-info
/// block in [ReceiptPrintDocument]. The period fits comfortably on one line
/// at 48 chars/line, so — unlike a left-aligned continuation line — it
/// doesn't need to wrap.
void _addPeriodLines(List<PrintInstruction> instructions,
    DateTime periodStart,
    DateTime periodEnd,
    DateTime generatedAt,) {
  instructions.add(
    PrintText(
      'Period: ${_fmtDate(periodStart)} - ${_fmtDate(periodEnd)}',
      align: PrintAlign.center,
    ),
  );
  instructions.add(
      PrintText('Printed: ${_fmtDate(generatedAt)}', align: PrintAlign.center));
}

void _sectionHeader(List<PrintInstruction> instructions, String title) {
  instructions.add(const PrintDivider());
  instructions.add(PrintText(title, bold: true));
}

void _amountRow(List<PrintInstruction> instructions,
    String label,
    double amount, {
      String currency = 'PHP',
    }) {
  instructions.add(PrintText(label));
  instructions.add(
    PrintText(
        '$currency ${amount.toStringAsFixed(2)}', align: PrintAlign.right),
  );
}

void _countRow(List<PrintInstruction> instructions, String label, int count) {
  instructions.add(PrintText(label));
  instructions.add(PrintText('$count', align: PrintAlign.right));
}

/// Itemized per-payment-method ledger, grouped by date, followed by a total
/// row — the printed counterpart of `PaymentLedgerSection` on screen.
void _paymentLedgerInstructions(List<PrintInstruction> instructions,
    PaymentLedger ledger, {
      String currency = 'PHP',
    }) {
  final nameUpper = ledger.displayName.toUpperCase();
  _sectionHeader(instructions, '$nameUpper LEDGER');
  for (final group in ledger.entriesByDate) {
    instructions.add(PrintText(_fmtDay(group.date), bold: true));
    for (final entry in group.entries) {
      final label =
          '${_fmtTime(entry.time)}  $nameUpper${entry.reference != null
          ? ' #${entry.reference}'
          : ''}';
      _amountRow(instructions, label, entry.amount, currency: currency);
    }
  }
  _amountRow(instructions, 'Total $nameUpper [${ledger.count}]', ledger.total,
      currency: currency);
}

String _fmtDay(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day
        .toString()
        .padLeft(2, '0')}';

String _fmtTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute
      .toString()
      .padLeft(2, '0')}';
}

String _fmtDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
