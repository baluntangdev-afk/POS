import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/entities/user_entity.dart';
import 'package:mobile/features/auth/state/auth_notifier.dart';
import 'package:mobile/features/auth/state/auth_providers.dart';
import 'package:mobile/features/auth/state/auth_state.dart';
import 'package:mobile/features/cashier_accounting/x_reading/state/x_reading_notifier.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final UserEntity user;
  _FakeAuthNotifier(this.user);

  @override
  AuthState build() => AuthAuthenticated(user);
}

void main() {
  Future<int> _seedCashier(AppDatabase db, String name) => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: name, role: 'cashier', pinHash: 'x'),
      );

  test('live X-Reading shows correct totals/counts for the current cashier only', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db, 'Ana');
    final otherId = await _seedCashier(db, 'Boy');

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: cashierId, status: 'completed', createdAt: DateTime.now()));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 50, type: 'dine_in', cashierId: cashierId, status: 'voided', createdAt: DateTime.now()));
    // Sale by a different cashier should not count toward this cashier's X-Reading.
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 999, type: 'dine_in', cashierId: otherId, status: 'completed', createdAt: DateTime.now()));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(UserEntity(id: cashierId, name: 'Ana', role: 'cashier'))),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final data = await container.read(xReadingProvider.future);

    expect(data.id, isNull);
    expect(data.cashierName, 'Ana');
    expect(data.totalSales, 100);
    expect(data.transactionCount, 1);
    expect(data.voidedCount, 1);
    expect(data.refundedCount, 0);
  });

  test('close() persists a row and a fresh subsequent read shows an empty period', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db, 'Ana');

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 200,
        type: 'dine_in',
        cashierId: cashierId,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5))));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(UserEntity(id: cashierId, name: 'Ana', role: 'cashier'))),
    ]);
    addTearDown(container.dispose);

    final before = await container.read(xReadingProvider.future);
    expect(before.totalSales, 200);

    await container.read(xReadingProvider.notifier).close();

    final after = container.read(xReadingProvider).value!;
    expect(after.totalSales, 0);
    expect(after.transactionCount, 0);

    final history = await db.cashierAccountingDao.getXReadingHistory(limit: 10, offset: 0);
    expect(history, hasLength(1));
    expect(history.first.totalSales, 200);
    expect(history.first.cashierId, cashierId);
  });
}
