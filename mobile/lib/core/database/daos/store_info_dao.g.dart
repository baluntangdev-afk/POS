// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_info_dao.dart';

// ignore_for_file: type=lint
mixin _$StoreInfoDaoMixin on DatabaseAccessor<AppDatabase> {
  $StoreInfoTableTable get storeInfoTable => attachedDatabase.storeInfoTable;
  $PaymentMethodsTableTable get paymentMethodsTable =>
      attachedDatabase.paymentMethodsTable;
  StoreInfoDaoManager get managers => StoreInfoDaoManager(this);
}

class StoreInfoDaoManager {
  final _$StoreInfoDaoMixin _db;
  StoreInfoDaoManager(this._db);
  $$StoreInfoTableTableTableManager get storeInfoTable =>
      $$StoreInfoTableTableTableManager(
        _db.attachedDatabase,
        _db.storeInfoTable,
      );
  $$PaymentMethodsTableTableTableManager get paymentMethodsTable =>
      $$PaymentMethodsTableTableTableManager(
        _db.attachedDatabase,
        _db.paymentMethodsTable,
      );
}
