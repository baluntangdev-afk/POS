import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/ordering/state/receipt_notifier.dart';

void main() {
  test('void_ marks the receipt voided with the given reason', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      status: 'completed',
      type: 'dine_in',
      createdAt: DateTime.now(),
    ));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(receiptProvider(saleId).future);
    await container.read(receiptProvider(saleId).notifier).void_('Customer changed mind');

    final receipt = container.read(receiptProvider(saleId)).value!;
    expect(receipt.isVoided, isTrue);
    expect(receipt.voidReason, 'Customer changed mind');
  });
}
