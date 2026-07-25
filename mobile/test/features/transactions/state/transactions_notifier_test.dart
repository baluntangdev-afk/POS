import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/transactions/state/transactions_notifier.dart';

void main() {
  Future<int> _seedCashier(AppDatabase db) => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
      );

  test('loads transactions from the database ordered newest first', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db);
    final now = DateTime.now();
    await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      type: 'take_out',
      status: 'completed',
      createdAt: now.subtract(const Duration(minutes: 1)),
    ));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 75,
      type: 'dine_in',
      status: 'completed',
      createdAt: now,
    ));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final result = await container.read(transactionsProvider.future);

    expect(result.items, hasLength(2));
    expect(result.items.first.total, 75); // newest first
  });

  test('search filters by invoice id', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db);
    final firstId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      type: 'take_out',
      status: 'completed',
      createdAt: DateTime.now(),
    ));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 75,
      type: 'dine_in',
      status: 'completed',
      createdAt: DateTime.now(),
    ));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(transactionsProvider.notifier).setSearch('#${firstId.toString().padLeft(6, '0')}');
    final result = await container.read(transactionsProvider.future);

    expect(result.items, hasLength(1));
    expect(result.items.first.id, firstId);
  });

  test('loadMore appends the next page without duplicating items, even when called concurrently', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db);
    final now = DateTime.now();
    for (var i = 0; i < 25; i++) {
      await db.salesDao.insertSale(SalesTableCompanion.insert(
        cashierId: cashierId,
        total: 50,
        type: 'take_out',
        status: 'completed',
        createdAt: now.subtract(Duration(minutes: 25 - i)),
      ));
    }

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(transactionsProvider.future);

    // Simulate a scroll-triggered race: two loadMore calls fired back-to-back
    // before the first resolves.
    final notifier = container.read(transactionsProvider.notifier);
    final first = notifier.loadMore();
    final second = notifier.loadMore();
    await Future.wait([first, second]);

    final result = container.read(transactionsProvider).value!;
    expect(result.items, hasLength(25));
    final ids = result.items.map((e) => e.id).toSet();
    expect(ids, hasLength(25));
  });

  test('voidTransaction marks the sale as voided', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db);
    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
      cashierId: cashierId,
      total: 50,
      type: 'take_out',
      status: 'completed',
      createdAt: DateTime.now(),
    ));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(transactionsProvider.future);
    await container.read(transactionsProvider.notifier).voidTransaction(saleId);

    final result = container.read(transactionsProvider).value!;
    final tx = result.items.firstWhere((e) => e.id == saleId);
    expect(tx.status, 'voided');
    expect(tx.isVoided, isTrue);
  });
}
