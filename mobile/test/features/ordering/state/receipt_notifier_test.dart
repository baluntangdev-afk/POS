import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/core/services/clock/app_clock.dart';
import 'package:mobile/features/ordering/state/receipt_notifier.dart';
import 'package:mobile/features/ordering/use_cases/void_sale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('voiding a sale marks its receipt voided with the given reason', () async {
    SharedPreferences.setMockInitialValues({});
    final appClock = await AppClock.load();
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

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      appClockProvider.overrideWithValue(appClock),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(receiptProvider(saleId).future);
    // Mirrors VoidTransactionDialog: void via the use case, then refresh.
    await container.read(voidSaleProvider)(saleId: saleId, reason: 'Customer changed mind');
    container.invalidate(receiptProvider(saleId));
    await container.read(receiptProvider(saleId).future);

    final receipt = container.read(receiptProvider(saleId)).value!;
    expect(receipt.isVoided, isTrue);
    expect(receipt.voidReason, 'Customer changed mind');
  });
}
