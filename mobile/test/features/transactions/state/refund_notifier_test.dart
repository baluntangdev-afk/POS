import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';
import 'package:mobile/features/ordering/use_cases/finalize_sale.dart';
import 'package:mobile/features/transactions/state/refund_notifier.dart';

void main() {
  test('confirmRefund saves the selected quantities with reason and method', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final sale = Sale(
      type: 'dine_in',
      createdAt: DateTime(2026, 7, 30),
      payment: const SalePayment(method: 'cash', amountPaid: 100, cashReceived: 100),
      items: [
        LineItem(
          id: 'a', productId: 1, productName: 'Burger', groupName: 'Mains',
          imageUrl: null, basePrice: 50, quantity: 2, modifiers: const [],
        ),
      ],
    );
    final receipt = await container.read(finalizeSaleProvider)(sale, cashierId: cashierId);

    final notifier = container.read(refundProvider(receipt.id).notifier);
    await container.read(refundProvider(receipt.id).future);

    final mainItem = receipt.items.single;
    notifier.toggleItemSelection(itemId: mainItem.id, maxQuantity: mainItem.quantity);
    notifier.changeReason('Wrong item');
    notifier.changeRefundMethod('Card Refund');
    await notifier.confirmRefund();

    final updated = await db.salesDao.getReceiptById(receipt.id);
    expect(updated!.refunds.single.reason, 'Wrong item');
    expect(updated.refunds.single.method, 'Card Refund');
    expect(updated.refundedAmount, 100);
  });
}
