import '../../features/ordering/entities/receipt.dart';
import '../../features/ordering/entities/receipt_item.dart';

enum PrintAlign { left, center, right }

sealed class PrintInstruction {
  const PrintInstruction();
}

class PrintText extends PrintInstruction {
  const PrintText(
    this.text, {
    this.align = PrintAlign.left,
    this.bold = false,
    this.sizeMultiplier = 1,
  });

  final String text;
  final PrintAlign align;
  final bool bold;
  final int sizeMultiplier;
}

class PrintRow extends PrintInstruction {
  const PrintRow({
    required this.columns,
    required this.weights,
    this.lastColumnAlign = PrintAlign.right,
    this.bold = false,
  });

  final List<String> columns;
  final List<int> weights;
  final PrintAlign lastColumnAlign;
  final bool bold;
}

class PrintDivider extends PrintInstruction {
  const PrintDivider({this.char = '-'});

  final String char;
}

class PrintFeed extends PrintInstruction {
  const PrintFeed(this.lines);

  final int lines;
}

abstract final class ReceiptPrintDocument {
  static List<PrintInstruction> build(
    Receipt receipt, {
    required String currency,
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
    String storeFooter = 'Thank you!',
  }) {
    final instructions = <PrintInstruction>[];

    _addStoreInfo(instructions, storeName, storeAddress, storeTin);
    instructions.add(const PrintDivider(char: '*'));
    _addDocumentInfo(instructions, receipt, terminalName);
    instructions.add(const PrintDivider(char: '*'));
    _addItems(instructions, receipt.items, currency);
    instructions.add(const PrintDivider());
    _addSummary(instructions, receipt, currency);

    if (receipt.hasRefunds) {
      instructions.add(const PrintDivider());
      _addRefunds(instructions, receipt, currency);
    }

    if (receipt.isVoided && receipt.voidReason != null) {
      instructions.add(const PrintDivider());
      instructions.add(const PrintText('VOID REASON:', bold: true));
      instructions.add(PrintText(receipt.voidReason!));
    }

    _addPayment(instructions, receipt, currency);

    instructions.add(
      PrintText(storeFooter.isNotEmpty ? storeFooter : 'Thank you!', align: PrintAlign.center),
    );
    instructions.add(const PrintFeed(1));
    instructions.add(const PrintFeed(3));

    return instructions;
  }

  static void _addStoreInfo(
    List<PrintInstruction> instructions,
    String? storeName,
    String? storeAddress,
    String? storeTin,
  ) {
    if (storeName != null && storeName.isNotEmpty) {
      instructions.add(PrintText(storeName, align: PrintAlign.center, bold: true));
    }
    if (storeAddress != null && storeAddress.isNotEmpty) {
      instructions.add(PrintText(storeAddress, align: PrintAlign.center));
    }
    if (storeTin != null && storeTin.isNotEmpty) {
      instructions.add(PrintText('TIN: $storeTin', align: PrintAlign.center));
    }
    instructions.add(const PrintText('Sales Invoice', align: PrintAlign.center, bold: true));
  }

  static void _addDocumentInfo(
    List<PrintInstruction> instructions,
    Receipt receipt,
    String? terminalName,
  ) {
    instructions.add(PrintText(_fmtDate(receipt.docDate)));
    instructions.add(PrintText('SI# ${receipt.docNumber}'));
    instructions.add(PrintText('Cashier: ${receipt.cashierName}'));
    if (terminalName != null && terminalName.isNotEmpty) {
      instructions.add(PrintText('Terminal: $terminalName'));
    }
  }

  static void _addItems(
    List<PrintInstruction> instructions,
    List<ReceiptItem> items,
    String currency,
  ) {
    for (final item in items) {
      final prefix = item.isMain ? '' : '  ';
      instructions.add(
        PrintRow(
          columns: [
            '$prefix${item.quantity} ${item.description}',
            '$currency ${item.totalAmount.toStringAsFixed(2)}',
          ],
          weights: const [8, 4],
        ),
      );
      if (item.isMain &&
          item.discountBeneficiaryName != null &&
          item.discountBeneficiaryName!.isNotEmpty) {
        instructions.add(
          PrintText(
            'LESS: ${item.discountType ?? 'Discount'} '
            '— ${item.discountBeneficiaryName} (${item.discountBeneficiaryId})',
          ),
        );
      }
    }
  }

  static void _addSummary(List<PrintInstruction> instructions, Receipt receipt, String currency) {
    instructions.add(_amountRow('VATable Sales', receipt.vatableAmount, currency));
    if (receipt.vatExemptSales > 0) {
      instructions.add(_amountRow('VAT-Exempt Sales', receipt.vatExemptSales, currency));
    }
    instructions.add(_amountRow('VAT', receipt.vatAmount, currency));
    if (receipt.discountAmount > 0) {
      instructions.add(_amountRow('Discount', -receipt.discountAmount, currency));
    }
    instructions.add(
      PrintRow(
        columns: ['TOTAL', '$currency ${receipt.totalAmount.toStringAsFixed(2)}'],
        weights: const [8, 4],
        bold: true,
      ),
    );
  }

  static void _addRefunds(List<PrintInstruction> instructions, Receipt receipt, String currency) {
    instructions.add(const PrintText('REFUNDS', bold: true));
    var totalRefund = 0.0;
    for (final refund in receipt.refunds) {
      instructions.add(PrintText('Reason: ${refund.reason}'));
      for (final ri in refund.items.where((ri) => ri.isMain)) {
        instructions.add(
          PrintRow(
            columns: [
              '${ri.quantity} ${ri.description}',
              '-$currency ${ri.refundAmount.toStringAsFixed(2)}',
            ],
            weights: const [8, 4],
          ),
        );
        totalRefund += ri.refundAmount;
      }
    }
    instructions.add(
      PrintRow(
        columns: ['Total Refund', '-$currency ${totalRefund.toStringAsFixed(2)}'],
        weights: const [8, 4],
        bold: true,
      ),
    );
    instructions.add(const PrintDivider());
    final netTotal = receipt.totalAmount - totalRefund;
    instructions.add(
      PrintRow(
        columns: ['Net Total', '$currency ${netTotal.toStringAsFixed(2)}'],
        weights: const [8, 4],
        bold: true,
      ),
    );
  }

  static void _addPayment(List<PrintInstruction> instructions, Receipt receipt, String currency) {
    final payment = receipt.payment;
    if (payment.method == 'cash') {
      instructions.add(_amountRow('Tendered', payment.cashReceived, currency));
      instructions.add(_amountRow('Change', payment.change, currency));
    } else {
      instructions.add(_amountRow(_methodLabel(payment.method), payment.amountPaid, currency));
      if (payment.reference != null && payment.reference!.isNotEmpty) {
        instructions.add(PrintText('Ref: ${payment.reference}'));
      }
    }
  }

  static PrintRow _amountRow(String label, double amount, String currency) {
    return PrintRow(
      columns: [label, '$currency ${amount.toStringAsFixed(2)}'],
      weights: const [8, 4],
    );
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String _methodLabel(String method) => switch (method) {
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };
}
