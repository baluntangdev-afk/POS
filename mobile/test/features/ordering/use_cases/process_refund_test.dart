import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';
import 'package:mobile/features/ordering/use_cases/finalize_sale.dart';
import 'package:mobile/features/ordering/use_cases/process_refund.dart';

void main() {
  test('ProcessRefund computes refund amount from unit price and saves via RefundRepository', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Mains'),
        );
    await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Burger'),
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
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 2,
          modifiers: const [],
        ),
      ],
    );
    final receipt = await container.read(finalizeSaleProvider)(sale, cashierId: cashierId);
    final mainItem = receipt.items.single;

    final refund = await container.read(processRefundProvider)(
      receipt: receipt,
      selectedQuantities: {mainItem.id: 1},
      reason: 'Wrong item',
      refundMethod: 'Cash Refund',
    );

    expect(refund.docNumber, startsWith('RF-'));
    expect(refund.items.single.refundAmount, 50);

    final updatedReceipt = await db.salesDao.getReceiptById(receipt.id);
    expect(updatedReceipt!.refundedAmount, 50);
  });
}
