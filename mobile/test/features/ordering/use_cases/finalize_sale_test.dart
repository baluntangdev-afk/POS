import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/entities/sale.dart';
import 'package:mobile/features/ordering/entities/sale_payment.dart';
import 'package:mobile/features/ordering/use_cases/finalize_sale.dart';

void main() {
  test('FinalizeSale saves the sale as pending then flips it to completed via the receipt', () async {
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
      payment: const SalePayment(method: 'cash', amountPaid: 50, cashReceived: 50),
      items: [
        LineItem(
          id: 'a',
          productId: 1,
          productName: 'Burger',
          groupName: 'Mains',
          imageUrl: null,
          basePrice: 50,
          quantity: 1,
          modifiers: const [],
        ),
      ],
    );

    final receipt = await container.read(finalizeSaleProvider)(sale, cashierId: cashierId);

    expect(receipt.isVoided, isFalse);
    expect(receipt.docNumber, startsWith('SO-'));
    expect(receipt.items.single.description, 'Burger');

    final row = await db.salesDao.getSaleById(receipt.id);
    expect(row!.status, 'completed');
  });

  test('FinalizeSale throws when the sale has no payment', () async {
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

    final sale = Sale(type: 'dine_in', createdAt: DateTime.now(), items: const []);

    expect(
      () => container.read(finalizeSaleProvider)(sale, cashierId: cashierId),
      throwsStateError,
    );
  });
}
