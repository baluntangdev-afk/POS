import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/users_table.dart';
import 'tables/product_groups_table.dart';
import 'tables/products_table.dart';
import 'tables/modifier_groups_table.dart';
import 'tables/modifier_options_table.dart';
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
import 'daos/users_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/store_info_dao.dart';
import 'daos/cashier_accounting_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersTable,
    ProductGroupsTable,
    ProductsTable,
    ModifierGroupsTable,
    ModifierOptionsTable,
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
  ],
  daos: [UsersDao, ProductsDao, SalesDao, StoreInfoDao, CashierAccountingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'mobile_pos'));

  @override
  int get schemaVersion => 5;

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
        },
      );
}
