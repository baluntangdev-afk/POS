import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/sale_items_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/refund_items_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<int> _seedSaleWithOneItem({required int qty, required double unitPrice}) async {
    final groupId = await db.into(db.productGroupsTable).insert(
          ProductGroupsTableCompanion.insert(name: 'Drinks'),
        );
    final productId = await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'),
        );
    final cashierId = await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
        );
    final saleId = await db.salesDao.insertSale(
      SalesTableCompanion.insert(
        cashierId: cashierId,
        total: unitPrice * qty,
        status: 'completed',
        type: 'dine_in',
        createdAt: DateTime.now(),
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

  test('recordRefund marks sale as refunded once fully refunded', () async {
    final saleId = await _seedSaleWithOneItem(qty: 2, unitPrice: 100);
    final items = await db.salesDao.getRefundableItems(saleId);
    expect(items, hasLength(1));

    await db.salesDao.recordRefund(
      saleId: saleId,
      total: 200,
      items: [(saleItemId: items.first.saleItemId, qty: 2)],
    );

    final sale = await db.salesDao.getSaleById(saleId);
    expect(sale!.status, 'refunded');

    final remaining = await db.salesDao.getRefundableItems(saleId);
    expect(remaining, isEmpty);
  });

  test('recordRefund leaves sale status completed on partial refund', () async {
    final saleId = await _seedSaleWithOneItem(qty: 2, unitPrice: 100);
    final items = await db.salesDao.getRefundableItems(saleId);

    await db.salesDao.recordRefund(
      saleId: saleId,
      total: 100,
      items: [(saleItemId: items.first.saleItemId, qty: 1)],
    );

    final sale = await db.salesDao.getSaleById(saleId);
    expect(sale!.status, 'completed');

    final remaining = await db.salesDao.getRefundableItems(saleId);
    expect(remaining, hasLength(1));
    expect(remaining.first.qty, 1);
  });

  test('recordRefund throws when refunding more than available', () async {
    final saleId = await _seedSaleWithOneItem(qty: 2, unitPrice: 100);
    final items = await db.salesDao.getRefundableItems(saleId);

    expect(
      () => db.salesDao.recordRefund(
        saleId: saleId,
        total: 300,
        items: [(saleItemId: items.first.saleItemId, qty: 3)],
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
