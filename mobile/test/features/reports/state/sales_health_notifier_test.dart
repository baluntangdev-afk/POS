import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/payments_table.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/sale_items_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/reports/state/reports_notifier.dart';
import 'package:mobile/features/reports/state/sales_health_notifier.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedCashier(String name) => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: name, role: 'cashier', pinHash: 'x'),
      );
  Future<int> _seedGroup(String name) =>
      db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
  Future<int> _seedProduct(int groupId, String name, double price) =>
      db.productsDao.insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: name));

  test('salesHealthProvider returns correctly-shaped and summed breakdowns for payment, cashier, and category', () async {
    final anaId = await _seedCashier('Ana');
    final boyId = await _seedCashier('Boy');
    final drinksId = await _seedGroup('Drinks');
    final foodId = await _seedGroup('Food');
    final latteId = await _seedProduct(drinksId, 'Latte', 100);
    final burgerId = await _seedProduct(foodId, 'Burger', 150);

    final now = DateTime.now();

    final sale1 = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', status: 'completed', cashierId: anaId, createdAt: now));
    await db.salesDao.insertPayment(PaymentsTableCompanion.insert(
        saleId: sale1, method: 'cash', amount: 100, createdAt: now));
    await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
        saleId: sale1, productId: latteId, variantName: '', qty: 1, unitPrice: 100));

    final sale2 = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 150, type: 'dine_in', status: 'completed', cashierId: boyId, createdAt: now));
    await db.salesDao.insertPayment(PaymentsTableCompanion.insert(
        saleId: sale2, method: 'card', amount: 150, createdAt: now));
    await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
        saleId: sale2, productId: burgerId, variantName: '', qty: 1, unitPrice: 150));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final data = await container.read(salesHealthProvider.future);

    // Payment breakdown
    expect(data.paymentBreakdown, hasLength(2));
    final cash = data.paymentBreakdown.firstWhere((p) => p.method == 'cash');
    final card = data.paymentBreakdown.firstWhere((p) => p.method == 'card');
    expect(cash.total, 100);
    expect(card.total, 150);
    expect(cash.percentage, closeTo(40, 0.01));
    expect(card.percentage, closeTo(60, 0.01));

    // Sales by cashier
    expect(data.salesByCashier, hasLength(2));
    expect(data.salesByCashier.firstWhere((c) => c.cashierName == 'Ana').total, 100);
    expect(data.salesByCashier.firstWhere((c) => c.cashierName == 'Boy').total, 150);

    // Sales by category
    expect(data.salesByCategory, hasLength(2));
    expect(data.salesByCategory.firstWhere((c) => c.groupName == 'Drinks').total, 100);
    expect(data.salesByCategory.firstWhere((c) => c.groupName == 'Food').total, 150);
  });

  test('setPeriod reloads data for the new period', () async {
    final cashierId = await _seedCashier('Ana');
    final groupId = await _seedGroup('Drinks');
    final productId = await _seedProduct(groupId, 'Latte', 100);

    // 2 days ago is always within "this month" unless run on the 1st/2nd —
    // acceptable given this mirrors ReportsNotifier's own period semantics.
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final oldSale = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 50, type: 'dine_in', status: 'completed', cashierId: cashierId, createdAt: twoDaysAgo));
    await db.salesDao.insertPayment(PaymentsTableCompanion.insert(
        saleId: oldSale, method: 'cash', amount: 50, createdAt: twoDaysAgo));
    await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
        saleId: oldSale, productId: productId, variantName: '', qty: 1, unitPrice: 50));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final today = await container.read(salesHealthProvider.future);
    expect(today.paymentBreakdown, isEmpty);

    await container.read(salesHealthProvider.notifier).setPeriod(ReportPeriod.month);
    final month = container.read(salesHealthProvider).value!;
    expect(month.paymentBreakdown, hasLength(1));
    expect(month.paymentBreakdown.first.total, 50);
  });

  test('timeSeries defaults to day granularity and buckets sales by day', () async {
    final cashierId = await _seedCashier('Ana');
    final groupId = await _seedGroup('Drinks');
    final productId = await _seedProduct(groupId, 'Latte', 100);

    final now = DateTime.now();
    final sale1 = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', status: 'completed', cashierId: cashierId, createdAt: now));
    await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
        saleId: sale1, productId: productId, variantName: '', qty: 1, unitPrice: 100));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    // "today" period so the seeded sale lands inside the queried range
    final data = await container.read(salesHealthProvider.future);
    expect(data.granularity, 'day');
    expect(data.timeSeries, isNotEmpty);
    expect(data.timeSeries.fold(0.0, (s, p) => s + p.total), 100);
  });

  test('setGranularity reloads the time series with the new bucketing', () async {
    final cashierId = await _seedCashier('Ana');
    final groupId = await _seedGroup('Drinks');
    final productId = await _seedProduct(groupId, 'Latte', 100);

    final now = DateTime.now();
    final sale1 = await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', status: 'completed', cashierId: cashierId, createdAt: now));
    await db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
        saleId: sale1, productId: productId, variantName: '', qty: 1, unitPrice: 100));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await container.read(salesHealthProvider.future);
    await container.read(salesHealthProvider.notifier).setGranularity('hour');
    final data = container.read(salesHealthProvider).value!;

    expect(data.granularity, 'hour');
    expect(data.timeSeries, isNotEmpty);
    expect(data.timeSeries.fold(0.0, (s, p) => s + p.total), 100);
  });
}
