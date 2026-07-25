import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/sale_items_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedGroup(String name) =>
      db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
  Future<int> _seedProduct(int groupId, String name, double price) =>
      db.productsDao.insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: name, price: price));
  Future<int> _seedCashier() => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
      );
  Future<int> _seedSale(int cashierId, double total, DateTime createdAt) =>
      db.salesDao.insertSale(SalesTableCompanion.insert(
          cashierId: cashierId, total: total, type: 'dine_in', status: 'completed', createdAt: createdAt));
  Future<void> _seedSaleItem(int saleId, int productId, int qty, double unitPrice) =>
      db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
          saleId: saleId, productId: productId, variantName: '', qty: qty, unitPrice: unitPrice));

  test('getSalesByProductGroup sums sale-item revenue grouped by category', () async {
    final drinksId = await _seedGroup('Drinks');
    final foodId = await _seedGroup('Food');
    final latteId = await _seedProduct(drinksId, 'Latte', 100);
    final burgerId = await _seedProduct(foodId, 'Burger', 150);
    final cashierId = await _seedCashier();

    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);
    final saleId = await _seedSale(cashierId, 250, DateTime(2026, 1, 1, 10));
    await _seedSaleItem(saleId, latteId, 1, 100);
    await _seedSaleItem(saleId, burgerId, 1, 150);

    final breakdown = await db.salesDao.getSalesByProductGroup(from, to);

    expect(breakdown, hasLength(2));
    expect(breakdown.firstWhere((r) => r.groupName == 'Drinks').total, 100);
    expect(breakdown.firstWhere((r) => r.groupName == 'Food').total, 150);
  });

  test('getSalesTimeSeries buckets completed sales totals by day', () async {
    final groupId = await _seedGroup('Drinks');
    await _seedProduct(groupId, 'Latte', 100);
    final cashierId = await _seedCashier();

    await _seedSale(cashierId, 100, DateTime(2026, 1, 1, 9));
    await _seedSale(cashierId, 50, DateTime(2026, 1, 1, 15));
    await _seedSale(cashierId, 75, DateTime(2026, 1, 2, 10));

    final series = await db.salesDao.getSalesTimeSeries(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 3),
      granularity: 'day',
    );

    expect(series, hasLength(2));
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-01').total, 150);
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-02').total, 75);
  });

  test('getSalesTimeSeries buckets by hour when granularity is hour', () async {
    final groupId = await _seedGroup('Drinks');
    await _seedProduct(groupId, 'Latte', 100);
    final cashierId = await _seedCashier();

    await _seedSale(cashierId, 100, DateTime(2026, 1, 1, 9, 15));
    await _seedSale(cashierId, 50, DateTime(2026, 1, 1, 9, 45));
    await _seedSale(cashierId, 75, DateTime(2026, 1, 1, 14, 0));

    final series = await db.salesDao.getSalesTimeSeries(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
      granularity: 'hour',
    );

    expect(series, hasLength(2));
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-01 09').total, 150);
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-01 14').total, 75);
  });
}
