import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ordering/entities/receipt.dart';
import 'package:mobile/features/ordering/entities/receipt_item.dart';
import 'package:mobile/features/ordering/entities/refund.dart';
import 'package:mobile/features/ordering/entities/refund_item.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';

Receipt _receipt({List<ReceiptItem>? items, List<Refund>? refunds}) => Receipt(
      id: 1,
      storeName: 'Store',
      cashierName: 'Cashier',
      docNumber: 'SO-000001',
      docDate: DateTime(2026, 7, 30),
      type: 'dine_in',
      payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 100),
      items: items ??
          const [
            ReceiptItem(
              id: 1,
              sequence: 1,
              description: 'Burger',
              quantity: 2,
              unitPrice: 50,
              grossAmount: 100,
              discountAmount: 0,
              totalAmount: 100,
              isMain: true,
            ),
          ],
      refunds: refunds ?? const [],
    );

void main() {
  test('totalAmount sums item totals', () {
    expect(_receipt().totalAmount, 100);
  });

  test('netTotalAmount subtracts refunded main-item amounts', () {
    final refund = Refund(
      id: 1,
      docNumber: 'RF-000001',
      docDate: DateTime(2026, 7, 30),
      receiptId: 1,
      reason: 'Wrong item',
      method: 'Cash Refund',
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
    final receipt = _receipt(refunds: [refund]);
    expect(receipt.hasRefunds, isTrue);
    expect(receipt.refundedAmount, 50);
    expect(receipt.netTotalAmount, 50);
    expect(receipt.refundedQuantities, {1: 1});
    expect(receipt.isFullyRefunded, isFalse);
  });

  test('isFullyRefunded is true when refunded quantity meets item quantity', () {
    final refund = Refund(
      id: 1,
      docNumber: 'RF-000001',
      docDate: DateTime(2026, 7, 30),
      receiptId: 1,
      reason: 'Wrong item',
      method: 'Cash Refund',
      items: const [
        RefundItem(
          id: 1,
          receiptItemId: 1,
          sequence: 1,
          description: 'Burger',
          quantity: 2,
          refundAmount: 100,
          isMain: true,
        ),
      ],
    );
    expect(_receipt(refunds: [refund]).isFullyRefunded, isTrue);
  });

  test('mainItemsWithAddOns groups add-on rows under their preceding main item', () {
    final items = [
      const ReceiptItem(
        id: 1, sequence: 1, description: 'Burger', quantity: 1, unitPrice: 50,
        grossAmount: 50, discountAmount: 0, totalAmount: 50, isMain: true,
      ),
      const ReceiptItem(
        id: -1, sequence: 1, description: 'Extra Cheese', quantity: 1, unitPrice: 10,
        grossAmount: 10, discountAmount: 0, totalAmount: 10, isMain: false,
      ),
    ];
    final grouped = _receipt(items: items).mainItemsWithAddOns;
    expect(grouped, hasLength(1));
    expect(grouped.first.mainItem.id, 1);
    expect(grouped.first.addOns.map((a) => a.id), [-1]);
  });
}
