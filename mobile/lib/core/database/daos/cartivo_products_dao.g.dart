// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cartivo_products_dao.dart';

// ignore_for_file: type=lint
mixin _$CartivoProductsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CartivoProductsTableTable get cartivoProductsTable =>
      attachedDatabase.cartivoProductsTable;
  $CartivoProductVariantsTableTable get cartivoProductVariantsTable =>
      attachedDatabase.cartivoProductVariantsTable;
  $CartivoSyncStateTableTable get cartivoSyncStateTable =>
      attachedDatabase.cartivoSyncStateTable;
  CartivoProductsDaoManager get managers => CartivoProductsDaoManager(this);
}

class CartivoProductsDaoManager {
  final _$CartivoProductsDaoMixin _db;
  CartivoProductsDaoManager(this._db);
  $$CartivoProductsTableTableTableManager get cartivoProductsTable =>
      $$CartivoProductsTableTableTableManager(
        _db.attachedDatabase,
        _db.cartivoProductsTable,
      );
  $$CartivoProductVariantsTableTableTableManager
  get cartivoProductVariantsTable =>
      $$CartivoProductVariantsTableTableTableManager(
        _db.attachedDatabase,
        _db.cartivoProductVariantsTable,
      );
  $$CartivoSyncStateTableTableTableManager get cartivoSyncStateTable =>
      $$CartivoSyncStateTableTableTableManager(
        _db.attachedDatabase,
        _db.cartivoSyncStateTable,
      );
}
