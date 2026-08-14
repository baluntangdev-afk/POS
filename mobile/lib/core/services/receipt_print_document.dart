import 'package:intl/intl.dart';

import '../../features/ordering/entities/receipt.dart';

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
  const PrintRow({required this.columns, this.weights, this.minGap = 1});

  /// Each column carries its own [PrintText.align]/[PrintText.bold] — a
  /// row is only rendered as a single physical line when every column
  /// shares the same [PrintText.bold], since one printed line can only
  /// carry one bold style.
  final List<PrintText> columns;

  /// Relative width of each column's slot. The slots always span the full
  /// printer line width edge-to-edge regardless of this ratio — [weights]
  /// only controls how that width is divided among [columns]. Omit it to
  /// give every column an equal share of the line.
  final List<int>? weights;

  /// Minimum number of spaces required between the label and amount
  /// columns. If the row's text is too long to leave at least this many
  /// spaces, the label and amount are printed on separate lines instead.
  final int minGap;

  List<int> get resolvedWeights => weights ?? List.filled(columns.length, 1);
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
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
    String storeFooter = 'Thank You!',
  }) {
    final instructions = <PrintInstruction>[];

    _addStoreInfo(instructions, storeName, storeAddress, storeTin);
    instructions.add(
      PrintText('********************', align: PrintAlign.center),
    );
    _addDocumentInfo(instructions, receipt, terminalName);
    instructions.add(
      PrintText('********************', align: PrintAlign.center),
    );
    _addItems(instructions, receipt);
    instructions.add(
      PrintText('********************', align: PrintAlign.center),
    );
    _addSummary(instructions, receipt);

    if (receipt.hasRefunds) {
      instructions.add(const PrintDivider());
      _addRefunds(instructions, receipt);
    }

    if (receipt.isVoided && receipt.voidReason != null) {
      instructions.add(
        PrintText('********************', align: PrintAlign.center),
      );
      instructions.add(
        const PrintText('VOID REASON:', bold: true, align: PrintAlign.center),
      );
      instructions.add(
        PrintText(receipt.voidReason!, align: PrintAlign.center),
      );
    }

    _addPayment(instructions, receipt);

    instructions.add(
      PrintText(
        storeFooter.isNotEmpty ? storeFooter : 'Thank You!',
        align: PrintAlign.center,
      ),
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
      instructions.add(
        PrintText(storeName, align: PrintAlign.center, bold: true),
      );
    }
    if (storeAddress != null && storeAddress.isNotEmpty) {
      instructions.add(PrintText(storeAddress, align: PrintAlign.center));
    }
    if (storeTin != null && storeTin.isNotEmpty) {
      instructions.add(PrintText('TIN: $storeTin', align: PrintAlign.center));
    }
    instructions.add(
      const PrintText('Sales Invoice', align: PrintAlign.center, bold: true),
    );
  }

  static void _addDocumentInfo(
    List<PrintInstruction> instructions,
    Receipt receipt,
    String? terminalName,
  ) {
    instructions.add(
      PrintText('SI# ${receipt.docNumber}', align: PrintAlign.center),
    );
    instructions.add(
      PrintText(_fmtDate(receipt.docDate), align: PrintAlign.center),
    );
    instructions.add(
      PrintText('Cashier: ${receipt.cashierName}', align: PrintAlign.center),
    );
    if (terminalName != null && terminalName.isNotEmpty) {
      instructions.add(
        PrintText('Terminal: $terminalName', align: PrintAlign.center),
      );
    }
  }

  static void _addItems(List<PrintInstruction> instructions, Receipt receipt) {
    final refundedQuantities = receipt.refundedQuantities;
    for (final item in receipt.items) {
      final prefix = item.isMain ? '' : '  ';
      instructions.add(
        PrintRow(
          columns: [
            PrintText('$prefix${item.quantity} ${item.description}'),
            PrintText(
              item.totalAmount.toStringAsFixed(2),
              align: PrintAlign.right,
            ),
          ],
          minGap: 10,
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
      if (item.isMain) {
        final refundedQty = refundedQuantities[item.id] ?? 0;
        if (refundedQty >= item.quantity && refundedQty > 0) {
          instructions.add(const PrintText('  (Fully Refunded)'));
        } else if (refundedQty > 0) {
          instructions.add(
            PrintText('  (Refunded: $refundedQty of ${item.quantity})'),
          );
        }
      }
    }
  }

  static void _addSummary(
    List<PrintInstruction> instructions,
    Receipt receipt,
  ) {
    instructions.add(PrintText('VATable Sales'));
    instructions.add(
      PrintText(
        receipt.vatableAmount.toStringAsFixed(2),
        align: PrintAlign.right,
      ),
    );
    if (receipt.vatExemptSales > 0) {
      instructions.add(PrintText('VAT-Exempt Sales'));
      instructions.add(
        PrintText(
          receipt.vatExemptSales.toStringAsFixed(2),
          align: PrintAlign.right,
        ),
      );
    }
    instructions.add(PrintText('VAT'));
    instructions.add(
      PrintText(receipt.vatAmount.toStringAsFixed(2), align: PrintAlign.right),
    );
    if (receipt.discountAmount > 0) {
      instructions.add(PrintText('Discount'));
      instructions.add(
        PrintText('${-receipt.discountAmount}', align: PrintAlign.right),
      );
    }
    instructions.add(PrintText('Total', bold: true));
    instructions.add(
      PrintText(
        receipt.totalAmount.toStringAsFixed(2),
        bold: true,
        align: PrintAlign.right,
      ),
    );
  }

  static void _addRefunds(
    List<PrintInstruction> instructions,
    Receipt receipt,
  ) {
    instructions.add(const PrintText('REFUNDS', bold: true));
    var totalRefund = 0.0;
    for (final refund in receipt.refunds) {
      instructions.add(PrintText('Reason: ${refund.reason}'));
      for (final ri in refund.items.where((ri) => ri.isMain)) {
        instructions.add(
          PrintRow(
            columns: [
              PrintText('${ri.quantity} ${ri.description}'),
              PrintText(
                '-${ri.refundAmount.toStringAsFixed(2)}',
                align: PrintAlign.right,
              ),
            ],
            weights: const [8, 4],
          ),
        );
        totalRefund += ri.refundAmount;
      }
    }
    instructions.add(
      PrintRow(
        columns: [
          const PrintText('Total Refund', bold: true),
          PrintText(
            '-${totalRefund.toStringAsFixed(2)}',
            align: PrintAlign.right,
            bold: true,
          ),
        ],
        weights: const [8, 4],
      ),
    );
    instructions.add(const PrintDivider());
    final netTotal = receipt.totalAmount - totalRefund;
    instructions.add(
      PrintRow(
        columns: [
          const PrintText('Net Total', bold: true),
          PrintText(
            netTotal.toStringAsFixed(2),
            align: PrintAlign.right,
            bold: true,
          ),
        ],
        weights: const [8, 4],
      ),
    );
  }

  static void _addPayment(
    List<PrintInstruction> instructions,
    Receipt receipt,
  ) {
    final payment = receipt.payment;
    if (payment.method == 'cash') {
      instructions.add(PrintText('Cash'));
      instructions.add(
        PrintText(
          payment.cashReceived.toStringAsFixed(2),
          align: PrintAlign.right,
        ),
      );
      instructions.add(PrintText('Change'));
      instructions.add(
        PrintText(payment.change.toStringAsFixed(2), align: PrintAlign.right),
      );
    } else {
      instructions.add(PrintText(payment.method));
      instructions.add(
        PrintText(
          payment.amountPaid.toStringAsFixed(2),
          align: PrintAlign.right,
        ),
      );
      if (payment.reference != null && payment.reference!.isNotEmpty) {
        instructions.add(
          PrintText('Ref: ${payment.reference}', align: PrintAlign.center),
        );
      }
    }
  }

  static String _fmtDate(DateTime dt) =>
      DateFormat.yMd().add_jm().format(dt.toLocal());
}
