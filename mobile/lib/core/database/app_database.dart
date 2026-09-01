import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/users_table.dart';
import 'tables/product_groups_table.dart';
import 'tables/products_table.dart';
import 'tables/product_variants_table.dart';
import 'tables/modifier_groups_table.dart';
import 'tables/modifier_options_table.dart';
import 'tables/product_modifier_groups_table.dart';
import 'tables/sales_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/sale_item_modifiers_table.dart';
import 'tables/payments_table.dart';
import 'tables/refunds_table.dart';
import 'tables/refund_items_table.dart';
import 'tables/store_info_table.dart';
import 'tables/x_readings_table.dart';
import 'tables/daily_reports_table.dart';
import 'tables/z_readings_table.dart';
import 'tables/payment_methods_table.dart';
import 'tables/order_events_table.dart';
import 'daos/users_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/store_info_dao.dart';
import 'daos/cashier_accounting_dao.dart';
import 'daos/order_events_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersTable,
    ProductGroupsTable,
    ProductsTable,
    ProductVariantsTable,
    ModifierGroupsTable,
    ModifierOptionsTable,
    ProductModifierGroupsTable,
    SalesTable,
    SaleItemsTable,
    SaleItemModifiersTable,
    PaymentsTable,
    RefundsTable,
    RefundItemsTable,
    StoreInfoTable,
    XReadingsTable,
    DailyReportsTable,
    ZReadingsTable,
    PaymentMethodsTable,
    OrderEventsTable,
  ],
  daos: [UsersDao, ProductsDao, SalesDao, StoreInfoDao, CashierAccountingDao, OrderEventsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'mobile_pos'));

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await storeInfoDao.ensureStoreInfoExists();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(xReadingsTable);
            await m.createTable(dailyReportsTable);
            await m.createTable(zReadingsTable);
          }
          if (from < 3) {
            await m.addColumn(storeInfoTable, storeInfoTable.tin);
            await m.createTable(paymentMethodsTable);
          }
          if (from < 4) {
            await m.addColumn(storeInfoTable, storeInfoTable.terminalName);
          }
          if (from < 5) {
            await m.addColumn(usersTable, usersTable.employeeId);
            await m.addColumn(usersTable, usersTable.phone);
            await m.addColumn(usersTable, usersTable.avatarUrl);
            await m.addColumn(usersTable, usersTable.isPinChanged);
          }
          if (from < 6) {
            await m.createTable(productVariantsTable);
            await m.createTable(productModifierGroupsTable);
            await m.addColumn(modifierGroupsTable, modifierGroupsTable.isActive);
            await m.addColumn(modifierOptionsTable, modifierOptionsTable.isActive);

            // Backfill one default variant per existing product, reading the
            // about-to-be-dropped `products.price` column directly via raw SQL —
            // the generated ProductsTable Dart class no longer exposes it.
            final existingProducts =
                await customSelect('SELECT id, price FROM products').get();
            for (final row in existingProducts) {
              await into(productVariantsTable).insert(ProductVariantsTableCompanion.insert(
                productId: row.read<int>('id'),
                name: 'Regular',
                price: row.read<double>('price'),
                isDefault: const Value(true),
                isActive: const Value(true),
              ));
            }

            // Backfill: link every existing modifier_groups row (which still has
            // a product_id column on disk at this point) to its original product
            // via the new junction table, and activate the group.
            final existingGroups =
                await customSelect('SELECT id, product_id FROM modifier_groups').get();
            for (final row in existingGroups) {
              await into(productModifierGroupsTable).insert(ProductModifierGroupsTableCompanion.insert(
                productId: row.read<int>('product_id'),
                modifierGroupId: row.read<int>('id'),
              ));
            }
            await customStatement('UPDATE modifier_groups SET is_active = 1');

            // Drop products.price. SQLite bundled with sqlite3_flutter_libs may not
            // support `ALTER TABLE ... DROP COLUMN`, so rebuild the table: create a
            // shadow table with the new (column-dropped) shape, copy data, swap it in.
            await customStatement('''
              CREATE TABLE products_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                group_id INTEGER NOT NULL REFERENCES product_groups (id),
                name TEXT NOT NULL,
                is_available INTEGER NOT NULL DEFAULT 1,
                image_url TEXT,
                sort_order INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await customStatement('''
              INSERT INTO products_new (id, group_id, name, is_available, image_url, sort_order)
              SELECT id, group_id, name, is_available, image_url, sort_order FROM products
            ''');
            await customStatement('DROP TABLE products');
            await customStatement('ALTER TABLE products_new RENAME TO products');

            // Drop modifier_groups.product_id the same way.
            await customStatement('''
              CREATE TABLE modifier_groups_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                is_required INTEGER NOT NULL DEFAULT 0,
                max_selections INTEGER NOT NULL DEFAULT 1,
                is_active INTEGER NOT NULL DEFAULT 1
              )
            ''');
            await customStatement('''
              INSERT INTO modifier_groups_new (id, name, is_required, max_selections, is_active)
              SELECT id, name, is_required, max_selections, is_active FROM modifier_groups
            ''');
            await customStatement('DROP TABLE modifier_groups');
            await customStatement('ALTER TABLE modifier_groups_new RENAME TO modifier_groups');
          }
          if (from < 7) {
            await m.addColumn(salesTable, salesTable.soNumber);
            await m.addColumn(salesTable, salesTable.voidReason);
            await m.addColumn(salesTable, salesTable.voidedAt);
            await m.addColumn(refundsTable, refundsTable.refundNumber);
            await m.addColumn(refundsTable, refundsTable.method);

            final existingSales = await customSelect('SELECT id FROM sales').get();
            for (final row in existingSales) {
              final id = row.read<int>('id');
              await customStatement(
                'UPDATE sales SET so_number = ? WHERE id = ?',
                ['SO-${id.toString().padLeft(6, '0')}', id],
              );
            }

            final existingRefunds = await customSelect('SELECT id FROM refunds').get();
            for (final row in existingRefunds) {
              final id = row.read<int>('id');
              await customStatement(
                'UPDATE refunds SET refund_number = ?, method = ? WHERE id = ?',
                ['RF-${id.toString().padLeft(6, '0')}', 'Cash Refund', id],
              );
            }
          }
          if (from < 8) {
            // Guarded with a column-existence check: if a prior run of this
            // migration was interrupted after adding some but not all of
            // these columns (e.g. a killed dev session), `user_version`
            // stays below 8 and this block re-runs from scratch on next
            // launch — a plain `addColumn` would then throw "duplicate
            // column name" on whatever already made it in.
            if (!await _hasColumn('sale_items', 'discount_type')) {
              await m.addColumn(saleItemsTable, saleItemsTable.discountType);
            }
            if (!await _hasColumn('sale_items', 'discount_beneficiary_id')) {
              await m.addColumn(saleItemsTable, saleItemsTable.discountBeneficiaryId);
            }
            if (!await _hasColumn('sale_items', 'discount_beneficiary_name')) {
              await m.addColumn(saleItemsTable, saleItemsTable.discountBeneficiaryName);
            }
            if (!await _hasColumn('sale_items', 'discount_amount')) {
              await m.addColumn(saleItemsTable, saleItemsTable.discountAmount);
            }
            if (!await _hasColumn('sale_items', 'vat_exempt_amount')) {
              await m.addColumn(saleItemsTable, saleItemsTable.vatExemptAmount);
            }
          }
          if (from < 9) {
            if (!await _hasColumn('x_readings', 'discounts_json')) {
              await m.addColumn(xReadingsTable, xReadingsTable.discountsJson);
            }
            if (!await _hasColumn('x_readings', 'total_discounts')) {
              await m.addColumn(xReadingsTable, xReadingsTable.totalDiscounts);
            }
            if (!await _hasColumn('x_readings', 'vatable_sales')) {
              await m.addColumn(xReadingsTable, xReadingsTable.vatableSales);
            }
            if (!await _hasColumn('x_readings', 'vat_amount')) {
              await m.addColumn(xReadingsTable, xReadingsTable.vatAmount);
            }
            if (!await _hasColumn('x_readings', 'vat_exempt_sales')) {
              await m.addColumn(xReadingsTable, xReadingsTable.vatExemptSales);
            }
            if (!await _hasColumn('x_readings', 'average_sale')) {
              await m.addColumn(xReadingsTable, xReadingsTable.averageSale);
            }
            if (!await _hasColumn('x_readings', 'highest_sale')) {
              await m.addColumn(xReadingsTable, xReadingsTable.highestSale);
            }
            if (!await _hasColumn('x_readings', 'lowest_sale')) {
              await m.addColumn(xReadingsTable, xReadingsTable.lowestSale);
            }
            if (!await _hasColumn('x_readings', 'cash_collected')) {
              await m.addColumn(xReadingsTable, xReadingsTable.cashCollected);
            }
            if (!await _hasColumn('z_readings', 'discounts_json')) {
              await m.addColumn(zReadingsTable, zReadingsTable.discountsJson);
            }
          }
          if (from < 10) {
            if (!await _hasColumn('x_readings', 'payment_ledgers_json')) {
              await m.addColumn(xReadingsTable, xReadingsTable.paymentLedgersJson);
            }
            if (!await _hasColumn('z_readings', 'payment_ledgers_json')) {
              await m.addColumn(zReadingsTable, zReadingsTable.paymentLedgersJson);
            }
          }
          if (from < 11) {
            if (!await _hasColumn('payments', 'cash_received')) {
              await m.addColumn(paymentsTable, paymentsTable.cashReceived);
            }
          }
          if (from < 12) {
            if (!await _hasColumn('store_info', 'store_id')) {
              await m.addColumn(storeInfoTable, storeInfoTable.storeId);
            }
          }
          if (from < 13) {
            await m.createTable(orderEventsTable);
          }
          if (from < 14) {
            // v14 briefly added order_events.sync_generation to drive a
            // generation-stamp sweep; that was replaced by a wipe-and-rebuild
            // history sync, so the column is no longer part of the schema.
            // Guarded so installs that ran the interim v14 (column present)
            // converge back to the column-less shape.
            if (await _hasColumn('order_events', 'sync_generation')) {
              await customStatement(
                'ALTER TABLE order_events DROP COLUMN sync_generation',
              );
            }
          }
        },
      );

  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.read<String>('name') == column);
  }
}
