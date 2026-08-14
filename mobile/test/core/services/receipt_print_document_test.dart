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
      expect(
        texts.any((t) => t.text == 'SI# SI-0001' && t.align == PrintAlign.center),
        isTrue,
      );
      expect(texts.any((t) => t.text == 'Terminal: POS-1'), isTrue);

      final rows = instructions.whereType<PrintRow>().toList();
      expect(
        rows.any(
          (r) =>
              r.columns[0].text == 'Total' &&
              r.columns[1].text == '100.00' &&
              r.columns[0].bold &&
              r.columns[1].bold,
        ),
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
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any(
          (t) => t.text == 'LESS: Senior Citizen / PWD — Juan Dela Cruz (SC-001)',
        ),
        isTrue,
      );
    });

    test('annotates partially and fully refunded items', () {
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
            refundAmount: 50,
            isMain: true,
          ),
        ],
      );

      final instructions = ReceiptPrintDocument.build(
        _receipt(items: [_item(quantity: 2, totalAmount: 200)], refunds: [refund]),
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == '  (Refunded: 1 of 2)'), isTrue);
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

      final instructions = ReceiptPrintDocument.build(_receipt(refunds: [refund]));

      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'REFUNDS' && t.bold), isTrue);
      expect(texts.any((t) => t.text == 'Reason: Customer changed mind'), isTrue);
      expect(texts.any((t) => t.text == '  (Fully Refunded)'), isTrue);

      final rows = instructions.whereType<PrintRow>().toList();
      expect(
        rows.any((r) => r.columns[0].text == 'Total Refund' && r.columns[1].text == '-100.00'),
        isTrue,
      );
      expect(
        rows.any((r) => r.columns[0].text == 'Net Total' && r.columns[1].text == '0.00'),
        isTrue,
      );
    });

    test('adds a VOID REASON block when the receipt is voided', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(isVoided: true, voidReason: 'Wrong order'),
      );

      final texts = instructions.whereType<PrintText>().toList();
      expect(texts.any((t) => t.text == 'VOID REASON:' && t.bold), isTrue);
      expect(
        texts.any((t) => t.text == 'Wrong order' && t.align == PrintAlign.center),
        isTrue,
      );
    });

    test('renders Cash and Change rows for cash payments', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 150)),
      );

      final rows = instructions.whereType<PrintRow>().toList();
      expect(rows.any((r) => r.columns[0].text == 'Cash' && r.columns[1].text == '150.00'), isTrue);
      expect(
        rows.any((r) => r.columns[0].text == 'Change' && r.columns[1].text == '50.00'),
        isTrue,
      );
    });

    test('renders method + centered Ref row for non-cash payments with a reference', () {
      final instructions = ReceiptPrintDocument.build(
        _receipt(
          payment: const SalePayment(
            method: 'card',
            amountPaid: 100,
            cashReceived: 0,
            reference: 'REF-999',
          ),
        ),
      );

      final rows = instructions.whereType<PrintRow>().toList();
      expect(rows.any((r) => r.columns[0].text == 'Card' && r.columns[1].text == '100.00'), isTrue);
      final texts = instructions.whereType<PrintText>().toList();
      expect(
        texts.any((t) => t.text == 'Ref: REF-999' && t.align == PrintAlign.center),
        isTrue,
      );
    });
  });
}
