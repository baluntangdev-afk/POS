# Mobile Built-In Printer Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Print receipts through the Nyx built-in thermal printer (AIDL service) when present, falling back to the existing Bluetooth path, with both paths rendering identical content that matches the on-screen receipt preview (including REFUNDS and VOID REASON sections currently missing from print output).

**Architecture:** A new pure-Dart `ReceiptPrintDocument.build()` turns a `Receipt` into an ordered list of abstract `PrintInstruction`s that mirror `_ReceiptPreview` section-for-section. `PrintService.printReceipt()` builds this document once, then routes it to a new `BuiltInPrinter` (Flutter `MethodChannel` → Kotlin plugin binding the Nyx AIDL service) when available, otherwise to a refactored `_printViaBluetooth()` that walks the same instruction list to emit ESC/POS bytes. `printXReading`/`printDailyReport`/`printZReading` are untouched.

**Tech Stack:** Flutter/Dart (`esc_pos_utils_plus`, `print_bluetooth_thermal`), Kotlin (Android `MethodChannel`, AIDL, `ServiceConnection`), no new dependencies.

---

### Task 1: `PrintInstruction` model + `ReceiptPrintDocument`

**Files:**
- Create: `mobile/lib/core/services/receipt_print_document.dart`
- Test: `mobile/test/core/services/receipt_print_document_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/receipt_print_document.dart';
import 'package:mobile/features/ordering/entities/receipt.dart';
import 'package:mobile/features/ordering/entities/receipt_item.dart';
import 'package:mobile/features/ordering/entities/refund.dart';
import 'package:mobile/features/ordering/entities/refund_item.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';

ReceiptItem _item({
  int id = 1,
  int sequence = 1,
  String description = 'Burger',
  int quantity = 1,
  double unitPrice = 100,
  double grossAmount = 100,
  double discountAmount = 0,
  double totalAmount = 100,
  bool isMain = true,
  String? discountType,
  String? discountBeneficiaryId,
  String? discountBeneficiaryName,
  double vatExemptAmount = 0,
}) {
  return ReceiptItem(
    id: id,
    sequence: sequence,
    description: description,
    quantity: quantity,
    unitPrice: unitPrice,
    grossAmount: grossAmount,
    discountAmount: discountAmount,
    totalAmount: totalAmount,
    isMain: isMain,
    discountType: discountType,
    discountBeneficiaryId: discountBeneficiaryId,
    discountBeneficiaryName: discountBeneficiaryName,
    vatExemptAmount: vatExemptAmount,
  );
}

Receipt _receipt({
  List<ReceiptItem>? items,
  List<Refund> refunds = const [],
  bool isVoided = false,
  String? voidReason,
  SalePayment? payment,
}) {
  return Receipt(
    id: 1,
    storeName: 'Test Store',
    cashierName: 'Jane Cashier',
    docNumber: 'SI-0001',
    docDate: DateTime(2026, 8, 1, 14, 30),
    type: 'dine_in',
    payment: payment ?? const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 200),
    items: items ?? [_item()],
    refunds: refunds,
    isVoided: isVoided,
    voidReason: voidReason,
  );
}

void main() {
  group('ReceiptPrintDocument.build', () {
    test('renders store info, sales invoice label, doc number, and total for a plain receipt', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(),
        currency: 'PHP',
        storeName: 'Test Store',
        storeAddress: '123 Main St',
        storeTin: '123-456-789',
        terminalName: 'POS-1',
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any((t) => t.text == 'Test Store' && t.align == PrintAlign.center && t.bold),
        isTrue,
      );
      expect(texts.any((t) => t.text == 'Sales Invoice'), isTrue);
      expect(texts.any((t) => t.text == 'SI# SI-0001'), isTrue);
      expect(texts.any((t) => t.text == 'Terminal: POS-1'), isTrue);

      final rows = instructions.whereType<PrintRow>().toList();
      expect(
        rows.any((r) => r.columns[0] == 'TOTAL' && r.columns[1] == 'PHP 100.00' && r.bold),
        isTrue,
      );

      expect(texts.any((t) => t.text == 'REFUNDS'), isFalse);
      expect(texts.any((t) => t.text == 'VOID REASON:'), isFalse);
    });

    test('adds a LESS beneficiary sub-line when an item has a discount beneficiary', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(
          items: [
            _item(
              discountType: 'Senior Citizen / PWD',
              discountBeneficiaryId: 'SC-001',
              discountBeneficiaryName: 'Juan Dela Cruz',
            ),
          ],
        ),
        currency: 'PHP',
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any(
          (t) => t.text == 'LESS: Senior Citizen / PWD — Juan Dela Cruz (SC-001)',
        ),
        isTrue,
      );
    });

    test('adds a REFUNDS section with reason, refunded items, and net total', () {
      final refund = Refund(
        id: 1,
        docNumber: 'RF-0001',
        docDate: DateTime(2026, 8, 1, 15),
        receiptId: 1,
        reason: 'Customer changed mind',
        method: 'cash',
        items: const [
          RefundItem(
            id: 1,
            receiptItemId: 1,
            sequence: 1,
            description: 'Burger',
            quantity: 1,
            refundAmount: 100,
            isMain: true,
          ),
        ],
      );

      final instructions = ReceiptPrintDocument.build(
        _receipt(refunds: [refund]),
        currency: 'PHP',
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'REFUNDS' && t.bold), isTrue);
      expect(texts.any((t) => t.text == 'Reason: Customer changed mind'), isTrue);

      final rows = instructions.whereType<PrintRow>().toList();
      expect(rows.any((r) => r.columns[0] == 'Total Refund' && r.columns[1] == '-PHP 100.00'), isTrue);
      expect(rows.any((r) => r.columns[0] == 'Net Total' && r.columns[1] == 'PHP 0.00'), isTrue);
    });

    test('adds a VOID REASON block when the receipt is voided', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(isVoided: true, voidReason: 'Wrong order'),
        currency: 'PHP',
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'VOID REASON:' && t.bold), isTrue);
      expect(texts.any((t) => t.text == 'Wrong order'), isTrue);
    });

    test('renders Tendered and Change rows for cash payments', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 150)),
        currency: 'PHP',
      );

      final rows = instructions.whereType<PrintRow>().toList();
      expect(rows.any((r) => r.columns[0] == 'Tendered' && r.columns[1] == 'PHP 150.00'), isTrue);
      expect(rows.any((r) => r.columns[0] == 'Change' && r.columns[1] == 'PHP 50.00'), isTrue);
    });

    test('renders method + Ref row for non-cash payments with a reference', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(
          payment: const SalePayment(
            method: 'card',
            amountPaid: 100,
            cashReceived: 0,
            reference: 'REF-999',
          ),
        ),
        currency: 'PHP',
      );

      final rows = instructions.whereType<PrintRow>().toList();
      expect(rows.any((r) => r.columns[0] == 'Card' && r.columns[1] == 'PHP 100.00'), isTrue);
      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'Ref: REF-999'), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/core/services/receipt_print_document_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/core/services/receipt_print_document.dart': No such file or directory.`

- [ ] **Step 3: Write the implementation**

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd mobile && flutter test test/core/services/receipt_print_document_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/core/services/receipt_print_document.dart mobile/test/core/services/receipt_print_document_test.dart
git commit -m "feat: add shared receipt print document builder"
```

---

### Task 2: Refactor `PrintService` Bluetooth path to consume `ReceiptPrintDocument`

**Files:**
- Modify: `mobile/lib/core/services/print_service.dart:1-235`

- [ ] **Step 1: Replace the imports and `printReceipt` body**

Replace lines 1-9 (imports) with:

```dart
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/ordering/entities/receipt.dart';
import 'built_in_printer.dart';
import 'receipt_print_document.dart';
```

(`built_in_printer.dart` is created in Task 3 — this import will not resolve until then; that's fine, this task's step 4 command is run after Task 3.)

Replace the entire `printReceipt` method (currently `mobile/lib/core/services/print_service.dart:36-235`, from `static Future<bool> printReceipt(` through its closing brace before `static Future<bool> printXReading`) with:

```dart
  static Future<bool> printReceipt(
    Receipt receipt, {
    String currency = 'PHP',
    String storeFooter = 'Thank you!',
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
  }) async {
    final document = ReceiptPrintDocument.build(
      receipt,
      currency: currency,
      storeName: storeName,
      storeAddress: storeAddress,
      storeTin: storeTin,
      terminalName: terminalName,
      storeFooter: storeFooter,
    );

    if (await BuiltInPrinter.isAvailable()) {
      return BuiltInPrinter.print(document);
    }

    return _printViaBluetooth(document);
  }

  static Future<bool> _printViaBluetooth(List<PrintInstruction> document) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();
      for (final instruction in document) {
        bytes += _encodeBluetoothInstruction(generator, instruction);
      }
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static List<int> _encodeBluetoothInstruction(
    Generator generator,
    PrintInstruction instruction,
  ) {
    return switch (instruction) {
      PrintText(:final text, :final align, :final bold, :final sizeMultiplier) => generator.text(
          text,
          styles: PosStyles(
            align: _posAlign(align),
            bold: bold,
            height: sizeMultiplier >= 2 ? PosTextSize.size2 : PosTextSize.size1,
            width: sizeMultiplier >= 2 ? PosTextSize.size2 : PosTextSize.size1,
          ),
        ),
      PrintRow(:final columns, :final weights, :final lastColumnAlign, :final bold) => generator
          .row([
            for (var i = 0; i < columns.length; i++)
              PosColumn(
                text: columns[i],
                width: weights[i],
                styles: PosStyles(
                  align: i == columns.length - 1 ? _posAlign(lastColumnAlign) : PosAlign.left,
                  bold: bold,
                ),
              ),
          ]),
      PrintDivider() => generator.hr(),
      PrintFeed(:final lines) => generator.feed(lines),
    };
  }

  static PosAlign _posAlign(PrintAlign align) => switch (align) {
        PrintAlign.left => PosAlign.left,
        PrintAlign.center => PosAlign.center,
        PrintAlign.right => PosAlign.right,
      };
```

- [ ] **Step 2: Confirm `printXReading`, `printDailyReport`, `printZReading`, and the `_fmtDay`/`_fmtDate`/`_fmtSaleType`/`_fmtMethod`/`_sectionHeader`/`_amountRow`/`_countRow` helpers below them are untouched**

These stay exactly as they were — this task only replaces the old `printReceipt` body. `_fmtDate`, `_fmtSaleType`, `_fmtMethod` are still used by the reading methods and remain in this file; `ReceiptPrintDocument` has its own private `_fmtDate`/`_methodLabel`, which is intentional duplication across the two files rather than a shared cross-file private helper.

- [ ] **Step 3: Soften the print-failure snackbar wording** (this can now fail via the built-in printer path too, not just "no printer configured")

In `mobile/lib/features/ordering/view/receipt_screen.dart`, find:

```dart
                                            ok
                                                ? 'Receipt printed'
                                                : 'No printer configured — go to Settings → Printer Setup',
```

Replace with:

```dart
                                            ok
                                                ? 'Receipt printed'
                                                : 'Couldn\'t print — check your printer and try again',
```

- [ ] **Step 4: Run static analysis** (deferred until Task 3 adds `built_in_printer.dart`, since this file now imports it)

Run: `cd mobile && dart analyze lib/core/services/print_service.dart lib/features/ordering/view/receipt_screen.dart`
Expected: no errors once Task 3 is complete.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/core/services/print_service.dart mobile/lib/features/ordering/view/receipt_screen.dart
git commit -m "refactor: drive Bluetooth receipt printing from ReceiptPrintDocument"
```

---

### Task 3: `BuiltInPrinter` Dart service + routing wire-up

**Files:**
- Create: `mobile/lib/core/services/built_in_printer.dart`

- [ ] **Step 1: Write the implementation**

```dart
import 'package:flutter/services.dart';

import 'receipt_print_document.dart';

const _channel = MethodChannel('com.dpo.mobile/nyx_printer');

abstract final class BuiltInPrinter {
  static bool? _availableCache;

  static Future<bool> isAvailable() async {
    if (_availableCache != null) return _availableCache!;
    try {
      _availableCache = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      _availableCache = false;
    }
    return _availableCache!;
  }

  static Future<bool> print(List<PrintInstruction> document) async {
    final payload = document.map(_encodeInstruction).toList();
    try {
      return await _channel.invokeMethod<bool>('printDocument', payload) ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Map<String, dynamic> _encodeInstruction(PrintInstruction instruction) {
    return switch (instruction) {
      PrintText(:final text, :final align, :final bold, :final sizeMultiplier) => {
          'type': 'text',
          'text': text,
          'align': align.name,
          'bold': bold,
          'sizeMultiplier': sizeMultiplier,
        },
      PrintRow(:final columns, :final weights, :final lastColumnAlign, :final bold) => {
          'type': 'row',
          'columns': columns,
          'weights': weights,
          'lastColumnAlign': lastColumnAlign.name,
          'bold': bold,
        },
      PrintDivider(:final char) => {'type': 'divider', 'char': char},
      PrintFeed(:final lines) => {'type': 'feed', 'lines': lines},
    };
  }
}
```

- [ ] **Step 2: Run static analysis across the printer files touched so far**

Run: `cd mobile && dart analyze lib/core/services/built_in_printer.dart lib/core/services/print_service.dart lib/core/services/receipt_print_document.dart`
Expected: no errors

- [ ] **Step 3: Run the full Dart test suite to confirm nothing else broke**

Run: `cd mobile && flutter test`
Expected: PASS (all existing suites plus `receipt_print_document_test.dart`)

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/core/services/built_in_printer.dart
git commit -m "feat: add BuiltInPrinter method-channel client and wire into PrintService"
```

---

### Task 4: Nyx AIDL contract

**Files:**
- Create: `mobile/android/app/src/main/aidl/net/nyx/printerservice/print/IPrinterService.aidl`
- Create: `mobile/android/app/src/main/aidl/net/nyx/printerservice/print/PrintTextFormat.aidl`
- Create: `mobile/android/app/src/main/java/net/nyx/printerservice/print/PrintTextFormat.java`

- [ ] **Step 1: Create the AIDL interface**

`mobile/android/app/src/main/aidl/net/nyx/printerservice/print/IPrinterService.aidl`:

```
package net.nyx.printerservice.print;

import net.nyx.printerservice.print.PrintTextFormat;

interface IPrinterService {
    int printText(String text, in PrintTextFormat textFormat);
    int printTableText(in String[] texts, in int[] weights, in PrintTextFormat[] formats);
    int paperOut(int px);
    int getPrinterStatus();
}
```

- [ ] **Step 2: Create the AIDL parcelable declaration**

`mobile/android/app/src/main/aidl/net/nyx/printerservice/print/PrintTextFormat.aidl`:

```
package net.nyx.printerservice.print;

parcelable PrintTextFormat;
```

- [ ] **Step 3: Create the parcelable's Java implementation**

`mobile/android/app/src/main/java/net/nyx/printerservice/print/PrintTextFormat.java`:

```java
package net.nyx.printerservice.print;

import android.os.Parcel;
import android.os.Parcelable;

public class PrintTextFormat implements Parcelable {
    public int textSize = 24;
    public int ali = 0; // 0 = left, 1 = center, 2 = right
    public int style = 0; // 0 = normal, 1 = bold

    public PrintTextFormat() {
    }

    protected PrintTextFormat(Parcel in) {
        textSize = in.readInt();
        ali = in.readInt();
        style = in.readInt();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(textSize);
        dest.writeInt(ali);
        dest.writeInt(style);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<PrintTextFormat> CREATOR = new Creator<PrintTextFormat>() {
        @Override
        public PrintTextFormat createFromParcel(Parcel in) {
            return new PrintTextFormat(in);
        }

        @Override
        public PrintTextFormat[] newArray(int size) {
            return new PrintTextFormat[size];
        }
    };
}
```

- [ ] **Step 4: Commit**

```bash
git add mobile/android/app/src/main/aidl/net/nyx/printerservice/print/IPrinterService.aidl \
        mobile/android/app/src/main/aidl/net/nyx/printerservice/print/PrintTextFormat.aidl \
        mobile/android/app/src/main/java/net/nyx/printerservice/print/PrintTextFormat.java
git commit -m "feat: add Nyx printer service AIDL contract"
```

---

### Task 5: `NyxPrinterPlugin` (Kotlin)

**Files:**
- Create: `mobile/android/app/src/main/kotlin/com/dpo/mobile/NyxPrinterPlugin.kt`

- [ ] **Step 1: Write the plugin**

```kotlin
package com.dpo.mobile

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.nyx.printerservice.print.IPrinterService
import net.nyx.printerservice.print.PrintTextFormat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

private const val CHANNEL_NAME = "com.dpo.mobile/nyx_printer"
private const val NYX_PACKAGE = "net.nyx.printerservice"
private const val NYX_ACTION = "net.nyx.printerservice.IPrinterService"
private const val BIND_TIMEOUT_SECONDS = 3L
private const val LINE_HEIGHT_PX = 24

class NyxPrinterPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result -> handleCall(call, result) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(isNyxPrinterInstalled())
            "printDocument" -> {
                @Suppress("UNCHECKED_CAST")
                val instructions = call.arguments as? List<Map<String, Any?>>
                if (instructions == null) {
                    result.success(false)
                    return
                }
                Thread {
                    val success = printDocument(instructions)
                    mainHandler.post { result.success(success) }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    private fun isNyxPrinterInstalled(): Boolean {
        return try {
            appContext.packageManager.getPackageInfo(NYX_PACKAGE, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun printDocument(instructions: List<Map<String, Any?>>): Boolean {
        val serviceRef = AtomicReference<IPrinterService?>()
        val latch = CountDownLatch(1)
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                serviceRef.set(binder?.let { IPrinterService.Stub.asInterface(it) })
                latch.countDown()
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                serviceRef.set(null)
                latch.countDown()
            }
        }

        val intent = Intent(NYX_ACTION).apply { setPackage(NYX_PACKAGE) }
        val bound =
            try {
                appContext.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            } catch (e: Exception) {
                false
            }
        if (!bound) return false

        return try {
            latch.await(BIND_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            val service = serviceRef.get() ?: return false
            for (instruction in instructions) {
                writeInstruction(service, instruction)
            }
            true
        } catch (e: Exception) {
            false
        } finally {
            try {
                appContext.unbindService(connection)
            } catch (e: Exception) {
                // already unbound
            }
        }
    }

    private fun writeInstruction(service: IPrinterService, instruction: Map<String, Any?>) {
        when (instruction["type"] as? String) {
            "text" -> service.printText(instruction["text"] as? String ?: "", textFormatFor(instruction))
            "row" -> {
                @Suppress("UNCHECKED_CAST")
                val columns = (instruction["columns"] as? List<String>)?.toTypedArray() ?: emptyArray()
                @Suppress("UNCHECKED_CAST")
                val weightsList = instruction["weights"] as? List<Int> ?: emptyList()
                val weights = IntArray(columns.size) { i -> weightsList.getOrElse(i) { 1 } }
                val bold = instruction["bold"] as? Boolean ?: false
                val lastAlign = instruction["lastColumnAlign"] as? String ?: "left"
                val formats =
                    Array(columns.size) { i ->
                        PrintTextFormat().apply {
                            textSize = 24
                            style = if (bold) 1 else 0
                            ali = if (i == columns.lastIndex) alignToInt(lastAlign) else 0
                        }
                    }
                service.printTableText(columns, weights, formats)
            }
            "divider" -> {
                val char = instruction["char"] as? String ?: "-"
                service.printText(char.repeat(32), PrintTextFormat())
            }
            "feed" -> {
                val lines = (instruction["lines"] as? Int) ?: 1
                service.paperOut(lines * LINE_HEIGHT_PX)
            }
        }
    }

    private fun textFormatFor(instruction: Map<String, Any?>): PrintTextFormat {
        val align = instruction["align"] as? String ?: "left"
        val bold = instruction["bold"] as? Boolean ?: false
        val sizeMultiplier = (instruction["sizeMultiplier"] as? Int) ?: 1
        return PrintTextFormat().apply {
            ali = alignToInt(align)
            style = if (bold) 1 else 0
            textSize = if (sizeMultiplier >= 2) 48 else 24
        }
    }

    private fun alignToInt(align: String): Int =
        when (align) {
            "center" -> 1
            "right" -> 2
            else -> 0
        }
}
```

Every AIDL call and the bind itself run inside the `try`/catch in `printDocument` (steps happen on a background `Thread`, not the platform/main thread), and `handleCall`'s `result.success(false)` fallback for a null `instructions` argument means the method channel never throws back to Dart — matching the spec's "any exception ... is caught and the method channel returns `false`" requirement.

- [ ] **Step 2: Commit**

```bash
git add mobile/android/app/src/main/kotlin/com/dpo/mobile/NyxPrinterPlugin.kt
git commit -m "feat: add NyxPrinterPlugin binding the Nyx AIDL printer service"
```

---

### Task 6: Register the plugin and declare package visibility

**Files:**
- Modify: `mobile/android/app/src/main/kotlin/com/dpo/mobile/MainActivity.kt`
- Modify: `mobile/android/app/src/main/AndroidManifest.xml:39-44`

- [ ] **Step 1: Register `NyxPrinterPlugin` in `MainActivity`**

Replace the full contents of `mobile/android/app/src/main/kotlin/com/dpo/mobile/MainActivity.kt` with:

```kotlin
package com.dpo.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NyxPrinterPlugin())
    }
}
```

- [ ] **Step 2: Add package visibility for `net.nyx.printerservice`**

In `mobile/android/app/src/main/AndroidManifest.xml`, the existing `<queries>` block is:

```xml
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
```

Replace with:

```xml
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <package android:name="net.nyx.printerservice"/>
    </queries>
```

- [ ] **Step 3: Build to confirm the Kotlin/AIDL/manifest changes compile**

Run: `cd mobile && flutter build apk --debug`
Expected: `BUILD SUCCESSFUL` — this compiles the AIDL stubs (`IPrinterService.Stub`), the Kotlin plugin, and validates the manifest.

- [ ] **Step 4: Commit**

```bash
git add mobile/android/app/src/main/kotlin/com/dpo/mobile/MainActivity.kt mobile/android/app/src/main/AndroidManifest.xml
git commit -m "feat: register NyxPrinterPlugin and declare Nyx printer package visibility"
```

---

### Task 7: Manual on-device verification

No code changes — this task is a checklist to run against the physical MIRAY/NB55 unit, since no emulator has `net.nyx.printerservice` installed.

- [ ] **Step 1: Run on the Nyx device**

Run: `cd mobile && flutter run -d <device-id>` (use `flutter devices` to find the MIRAY unit's id)

- [ ] **Step 2: Verify built-in printer path**

Complete a plain cash sale and print the receipt. Confirm:
- Store name/address/TIN centered, "Sales Invoice" label
- Date, `SI# <docNumber>`, cashier, terminal name
- Items with correct qty/description/amount
- VATable Sales / VAT / Total rows
- Tendered / Change rows
- Trailing feed with no cut (tear-bar) — paper should not be cut

- [ ] **Step 3: Verify senior/PWD discount parity**

Complete a sale with a Senior/PWD discount applied. Confirm the printed `LESS: Senior Citizen / PWD — <name> (<id>)` sub-line matches the on-screen preview exactly.

- [ ] **Step 4: Verify refund parity**

Refund part of a completed sale, reprint from the transaction/receipt screen. Confirm the REFUNDS section (reason, refunded line items, Total Refund, Net Total) matches the preview.

- [ ] **Step 5: Verify void parity**

Void a transaction, reprint. Confirm the VOID REASON block matches the preview.

- [ ] **Step 6: Verify Bluetooth fallback still works**

Temporarily disable `net.nyx.printerservice` (`adb shell pm disable-user --user 0 net.nyx.printerservice`, re-enable afterward with `pm enable`) or test on a non-Nyx device with a paired Bluetooth printer. Confirm printing still succeeds via Bluetooth with the same content parity, and that the printer cuts the paper (Bluetooth path keeps `cut()`).

- [ ] **Step 7: Verify graceful failure**

With no built-in printer and no Bluetooth printer paired, attempt to print. Confirm the snackbar reads "Couldn't print — check your printer and try again" and the app does not crash or hang.

---

## Spec coverage check

- Built-in printer detection + preference over Bluetooth, fallback when unavailable: Task 2 (`printReceipt` routing), Task 3 (`BuiltInPrinter.isAvailable`).
- Full preview parity (store info, Sales Invoice, items + LESS sub-line, VAT/summary, REFUNDS, VOID REASON, payment) for both paths: Task 1 (`ReceiptPrintDocument`), consumed identically by Task 2 (Bluetooth) and Task 3 (built-in).
- `printXReading`/`printDailyReport`/`printZReading` untouched: explicitly called out in Task 2 Step 2.
- AIDL files + `PrintTextFormat`: Task 4.
- `NyxPrinterPlugin.kt` binding/timeout/unbind/exception-swallowing: Task 5.
- Manual plugin registration in `MainActivity`, manifest `<queries>` entry: Task 6.
- Error handling (unavailable is not an error, bind timeout/AIDL exceptions caught, no retries, snackbar wording): Task 2 Step 3, Task 5 Step 1 note.
- Testing: `ReceiptPrintDocument.build()` fixtures (plain/discount/refund/voided) in Task 1; hardware-only verification in Task 7.
