import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/payments_table.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/store_info_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/entities/user_entity.dart';
import 'package:mobile/features/auth/state/auth_notifier.dart';
import 'package:mobile/features/auth/state/auth_providers.dart';
import 'package:mobile/features/auth/state/auth_state.dart';
import 'package:mobile/features/cashier_accounting/daily_report/state/daily_report_notifier.dart';

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

  test('live Daily Report computes gross/VAT/netOfTax/cashSales for the current cashier', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db, 'Ana');
    final otherId = await _seedCashier(db, 'Boy');

    // Store tax rate is auto-created via ensureStoreInfoExists() on onCreate; update it to a known rate.
    final store = await db.storeInfoDao.getStoreInfo();
    await db.storeInfoDao.upsertStoreInfo(
      StoreInfoTableCompanion(id: Value(store!.id), taxRate: const Value(0.12)),
    );

    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 112, type: 'dine_in', cashierId: cashierId, status: 'completed', createdAt: DateTime.now()));
    await db.salesDao.insertPayment(PaymentsTableCompanion.insert(
        saleId: saleId, method: 'cash', amount: 112, createdAt: DateTime.now()));

    // Sale by a different cashier should not count toward this cashier's Daily Report.
    final otherSaleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 999, type: 'dine_in', cashierId: otherId, status: 'completed', createdAt: DateTime.now()));
    await db.salesDao.insertPayment(PaymentsTableCompanion.insert(
        saleId: otherSaleId, method: 'cash', amount: 999, createdAt: DateTime.now()));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(UserEntity(id: cashierId, name: 'Ana', role: 'cashier'))),
    ]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final data = await container.read(dailyReportProvider.future);

    expect(data.id, isNull);
    expect(data.cashierName, 'Ana');
    expect(data.grossSales, 112);
    expect(data.vatableSales, closeTo(100, 0.01));
    expect(data.vatAmount, closeTo(12, 0.01));
    expect(data.vatExemptSales, 0);
    expect(data.netOfTax, closeTo(100, 0.01));
    expect(data.transactionCount, 1);
    expect(data.totalQtySold, 0);
    expect(data.cashSalesTotal, 112);
    expect(data.cashSalesCount, 1);
  });

  test('close() persists a row and a fresh subsequent read shows an empty period', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final cashierId = await _seedCashier(db, 'Ana');

    final saleId = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 200,
        type: 'dine_in',
        cashierId: cashierId,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5))));
    await db.salesDao.insertPayment(PaymentsTableCompanion.insert(
        saleId: saleId, method: 'cash', amount: 200, createdAt: DateTime.now()));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(UserEntity(id: cashierId, name: 'Ana', role: 'cashier'))),
    ]);
    addTearDown(container.dispose);

    final before = await container.read(dailyReportProvider.future);
    expect(before.grossSales, 200);

    await container.read(dailyReportProvider.notifier).close();

    final after = container.read(dailyReportProvider).value!;
    expect(after.grossSales, 0);
    expect(after.transactionCount, 0);

    final history = await db.cashierAccountingDao.getDailyReportHistory(limit: 10, offset: 0);
    expect(history, hasLength(1));
    expect(history.first.grossSales, 200);
    expect(history.first.cashierId, cashierId);
  });
}
