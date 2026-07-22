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
import 'daos/users_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/store_info_dao.dart';

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
  ],
  daos: [UsersDao, ProductsDao, SalesDao, StoreInfoDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'mobile_pos'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await storeInfoDao.ensureStoreInfoExists();
        },
      );
}
