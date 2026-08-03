import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/entities/discount.dart';
import 'package:mobile/features/ordering/entities/line_item.dart';
import 'package:mobile/features/ordering/state/ordering_notifier.dart';

void main() {
  test('confirmSale saves the cart as a completed Sale and clears the cart', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Mains'),
        );
    final productId = await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Burger'),
        );
    await db.into(db.productVariantsTable).insert(
          ProductVariantsTableCompanion.insert(productId: productId, name: 'Regular', price: 50),
        );

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(orderingProvider.future);
    container.read(orderingProvider.notifier).addItem(
          LineItem(
            id: 'a',
            productId: productId,
            productName: 'Burger',
            groupName: 'Mains',
            imageUrl: null,
            basePrice: 50,
            quantity: 1,
            modifiers: const [],
          ),
        );

    final receipt = await container.read(orderingProvider.notifier).confirmSale(
          cashierId: cashierId,
          method: 'cash',
          amountPaid: 50,
        );

    expect(receipt.docNumber, startsWith('SO-'));
    final row = await db.salesDao.getSaleById(receipt.id);
    expect(row!.status, 'completed');

    final cart = container.read(orderingProvider).value!;
    expect(cart.sale.items, isEmpty);
  });

  test('applyDiscount splits a partially-selected line item and discounts only the selected qty',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(orderingProvider.future);
    final notifier = container.read(orderingProvider.notifier);
    notifier.addItem(
      const LineItem(
        id: 'a',
        productId: 1,
        productName: 'Burger',
        groupName: 'Mains',
        imageUrl: null,
        basePrice: 50,
        quantity: 3,
        modifiers: [],
      ),
    );

    notifier.applyDiscount(
      {'a': 2},
      (item, quantity) => const SeniorPwdDiscount(beneficiaryId: '123', beneficiaryName: 'Juan'),
    );

    final items = container.read(orderingProvider).value!.sale.items;
    expect(items, hasLength(2));
    final undiscounted = items.firstWhere((i) => i.discount == null);
    final discounted = items.firstWhere((i) => i.discount != null);
    expect(undiscounted.quantity, 1);
    expect(discounted.quantity, 2);
    expect(discounted.discount, isA<SeniorPwdDiscount>());
  });
}
