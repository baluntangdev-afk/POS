import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/sale_items_table.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedCashier(String name) => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: name, role: 'user', pinHash: 'x'),
      );

  Future<int> _seedSaleWithOneItem({
    required int cashierId,
    required int qty,
    required double unitPrice,
    required DateTime createdAt,
  }) async {
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Drinks'),
        );
    final productId = await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: unitPrice),
        );
    final saleId = await db.salesDao.insertSale(
      SalesTableCompanion.insert(
        cashierId: cashierId,
        total: unitPrice * qty,
        status: 'completed',
        type: 'dine_in',
        createdAt: createdAt,
      ),
    );
    await db.salesDao.insertSaleItem(
      SaleItemsTableCompanion.insert(
        saleId: saleId,
        productId: productId,
        variantName: '',
        qty: qty,
        unitPrice: unitPrice,
      ),
    );
    return saleId;
  }

  test('getStatusCountsForDateRange counts voided and refunded separately from completed', () async {
    final cashierId = await _seedCashier('Ana');
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: cashierId, status: 'completed', createdAt: DateTime(2026, 1, 1, 10)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 50, type: 'dine_in', cashierId: cashierId, status: 'voided', createdAt: DateTime(2026, 1, 1, 11)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 75, type: 'dine_in', cashierId: cashierId, status: 'refunded', createdAt: DateTime(2026, 1, 1, 12)));

    final counts = await db.salesDao.getStatusCountsForDateRange(from, to);
    expect(counts.completed, 1);
    expect(counts.voided, 1);
    expect(counts.refunded, 1);
  });

  test('getSalesByCashier groups totals per cashier within a date range', () async {
    final anaId = await _seedCashier('Ana');
    final boyId = await _seedCashier('Boy');
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: anaId, status: 'completed', createdAt: DateTime(2026, 1, 1, 10)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 60, type: 'dine_in', cashierId: boyId, status: 'completed', createdAt: DateTime(2026, 1, 1, 11)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 40, type: 'dine_in', cashierId: anaId, status: 'completed', createdAt: DateTime(2026, 1, 1, 12)));

    final byCashier = await db.salesDao.getSalesByCashier(from, to);
    expect(byCashier, hasLength(2));
    final ana = byCashier.firstWhere((r) => r.cashierName == 'Ana');
    expect(ana.total, 140);
    expect(ana.transactionCount, 2);
  });

  test('getRefundTotalForDateRange sums refund amounts within range', () async {
    final cashierId = await _seedCashier('Ana');
    // recordRefund stamps createdAt with DateTime.now(), so the range must
    // bracket "now" rather than a fixed historical date.
    final from = DateTime.now().subtract(const Duration(minutes: 5));
    final to = DateTime.now().add(const Duration(minutes: 5));

    final saleId = await _seedSaleWithOneItem(
      cashierId: cashierId,
      qty: 2,
      unitPrice: 100,
      createdAt: DateTime.now(),
    );
    final items = await db.salesDao.getRefundableItems(saleId);

    await db.salesDao.recordRefund(
      saleId: saleId,
      total: 200,
      items: [(saleItemId: items.first.saleItemId, qty: 2)],
    );

    final total = await db.salesDao.getRefundTotalForDateRange(from, to);
    expect(total, 200);
  });
}
