// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductGroupsTableTable get productGroupsTable =>
      attachedDatabase.productGroupsTable;
  $ProductsTableTable get productsTable => attachedDatabase.productsTable;
  $ProductVariantsTableTable get productVariantsTable =>
      attachedDatabase.productVariantsTable;
  $ModifierGroupsTableTable get modifierGroupsTable =>
      attachedDatabase.modifierGroupsTable;
  $ModifierOptionsTableTable get modifierOptionsTable =>
      attachedDatabase.modifierOptionsTable;
  $ProductModifierGroupsTableTable get productModifierGroupsTable =>
      attachedDatabase.productModifierGroupsTable;
  ProductsDaoManager get managers => ProductsDaoManager(this);
}

class ProductsDaoManager {
  final _$ProductsDaoMixin _db;
  ProductsDaoManager(this._db);
  $$ProductGroupsTableTableTableManager get productGroupsTable =>
      $$ProductGroupsTableTableTableManager(
        _db.attachedDatabase,
        _db.productGroupsTable,
      );
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db.attachedDatabase, _db.productsTable);
  $$ProductVariantsTableTableTableManager get productVariantsTable =>
      $$ProductVariantsTableTableTableManager(
        _db.attachedDatabase,
        _db.productVariantsTable,
      );
  $$ModifierGroupsTableTableTableManager get modifierGroupsTable =>
      $$ModifierGroupsTableTableTableManager(
        _db.attachedDatabase,
        _db.modifierGroupsTable,
      );
  $$ModifierOptionsTableTableTableManager get modifierOptionsTable =>
      $$ModifierOptionsTableTableTableManager(
        _db.attachedDatabase,
        _db.modifierOptionsTable,
      );
  $$ProductModifierGroupsTableTableTableManager
  get productModifierGroupsTable =>
      $$ProductModifierGroupsTableTableTableManager(
        _db.attachedDatabase,
        _db.productModifierGroupsTable,
      );
}
