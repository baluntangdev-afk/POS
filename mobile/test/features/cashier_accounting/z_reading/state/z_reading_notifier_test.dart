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
import 'package:mobile/features/cashier_accounting/z_reading/state/z_reading_notifier.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final UserEntity user;
  _FakeAuthNotifier(this.user);

  @override
  AuthState build() => AuthAuthenticated(user);
}

void main() {
  Future<int> _seedUser(AppDatabase db, String name, {String role = 'cashier'}) =>
      db.into(db.usersTable).insert(
            UsersTableCompanion.insert(name: name, role: role, pinHash: 'x'),
          );

  test('live Z-Reading combines totals across BOTH cashiers (store-wide, not scoped)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final anaId = await _seedUser(db, 'Ana');
    final boyId = await _seedUser(db, 'Boy');
    final adminId = await _seedUser(db, 'Admin', role: 'admin');

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: anaId, status: 'completed', createdAt: DateTime.now()));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 60, type: 'dine_in', cashierId: boyId, status: 'completed', createdAt: DateTime.now()));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 50, type: 'dine_in', cashierId: anaId, status: 'voided', createdAt: DateTime.now()));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(UserEntity(id: adminId, name: 'Admin', role: 'admin'))),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final data = await container.read(zReadingProvider.future);

    expect(data.id, isNull);
    expect(data.totalSales, 160); // 100 (Ana) + 60 (Boy)
    expect(data.transactionCount, 2);
    expect(data.voidedCount, 1);
    expect(data.salesByCashier, hasLength(2));
    final anaBreakdown = data.salesByCashier.firstWhere((c) => c.cashierName == 'Ana');
    expect(anaBreakdown.total, 100);
  });

  test('close() does not re-check PIN, persists a row, increments zCounter, and resets the live period', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedUser(db, 'Ana');
    final adminId = await _seedUser(db, 'Admin', role: 'admin');

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 300,
        type: 'dine_in',
        cashierId: cashierId,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5))));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(UserEntity(id: cashierId, name: 'Ana', role: 'cashier'))),
    ]);
    addTearDown(container.dispose);

    final before = await container.read(zReadingProvider.future);
    expect(before.totalSales, 300);

    await container.read(zReadingProvider.notifier).close(
          closedByUserId: cashierId,
          closedByName: 'Ana',
          authorizedByUserId: 0,
          authorizedByName: 'Supervisor',
          beginningBalance: 500,
          endingBalance: 800,
        );

    final after = container.read(zReadingProvider).value!;
    expect(after.totalSales, 0);
    expect(after.transactionCount, 0);

    final nextZCounter = await db.cashierAccountingDao.getNextZCounter();
    expect(nextZCounter, 2);

    final history = await db.cashierAccountingDao.getZReadingHistory(limit: 10, offset: 0);
    expect(history, hasLength(1));
    expect(history.first.zCounter, 1);
    expect(history.first.totalSales, 300);
    expect(history.first.authorizedByName, 'Supervisor');
    expect(history.first.beginningBalance, 500);
    expect(history.first.endingBalance, 800);
    expect(adminId, isPositive); // admin seeded for realism, not directly asserted further
  });
}
