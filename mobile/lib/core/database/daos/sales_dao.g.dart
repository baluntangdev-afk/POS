// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_dao.dart';

// ignore_for_file: type=lint
mixin _$SalesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  $SalesTableTable get salesTable => attachedDatabase.salesTable;
  $ProductGroupsTableTable get productGroupsTable =>
      attachedDatabase.productGroupsTable;
  $ProductsTableTable get productsTable => attachedDatabase.productsTable;
  $SaleItemsTableTable get saleItemsTable => attachedDatabase.saleItemsTable;
  $SaleItemModifiersTableTable get saleItemModifiersTable =>
      attachedDatabase.saleItemModifiersTable;
  $PaymentsTableTable get paymentsTable => attachedDatabase.paymentsTable;
  $RefundsTableTable get refundsTable => attachedDatabase.refundsTable;
  $RefundItemsTableTable get refundItemsTable =>
      attachedDatabase.refundItemsTable;
  SalesDaoManager get managers => SalesDaoManager(this);
}

class SalesDaoManager {
  final _$SalesDaoMixin _db;
  SalesDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
  $$SalesTableTableTableManager get salesTable =>
      $$SalesTableTableTableManager(_db.attachedDatabase, _db.salesTable);
  $$ProductGroupsTableTableTableManager get productGroupsTable =>
      $$ProductGroupsTableTableTableManager(
        _db.attachedDatabase,
        _db.productGroupsTable,
      );
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db.attachedDatabase, _db.productsTable);
  $$SaleItemsTableTableTableManager get saleItemsTable =>
      $$SaleItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.saleItemsTable,
      );
  $$SaleItemModifiersTableTableTableManager get saleItemModifiersTable =>
      $$SaleItemModifiersTableTableTableManager(
        _db.attachedDatabase,
        _db.saleItemModifiersTable,
      );
  $$PaymentsTableTableTableManager get paymentsTable =>
      $$PaymentsTableTableTableManager(_db.attachedDatabase, _db.paymentsTable);
  $$RefundsTableTableTableManager get refundsTable =>
      $$RefundsTableTableTableManager(_db.attachedDatabase, _db.refundsTable);
  $$RefundItemsTableTableTableManager get refundItemsTable =>
      $$RefundItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.refundItemsTable,
      );
}
