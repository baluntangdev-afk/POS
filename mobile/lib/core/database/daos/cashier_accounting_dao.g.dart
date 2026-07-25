// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashier_accounting_dao.dart';

// ignore_for_file: type=lint
mixin _$CashierAccountingDaoMixin on DatabaseAccessor<AppDatabase> {
  $XReadingsTableTable get xReadingsTable => attachedDatabase.xReadingsTable;
  $DailyReportsTableTable get dailyReportsTable =>
      attachedDatabase.dailyReportsTable;
  $ZReadingsTableTable get zReadingsTable => attachedDatabase.zReadingsTable;
  CashierAccountingDaoManager get managers => CashierAccountingDaoManager(this);
}

class CashierAccountingDaoManager {
  final _$CashierAccountingDaoMixin _db;
  CashierAccountingDaoManager(this._db);
  $$XReadingsTableTableTableManager get xReadingsTable =>
      $$XReadingsTableTableTableManager(
        _db.attachedDatabase,
        _db.xReadingsTable,
      );
  $$DailyReportsTableTableTableManager get dailyReportsTable =>
      $$DailyReportsTableTableTableManager(
        _db.attachedDatabase,
        _db.dailyReportsTable,
      );
  $$ZReadingsTableTableTableManager get zReadingsTable =>
      $$ZReadingsTableTableTableManager(
        _db.attachedDatabase,
        _db.zReadingsTable,
      );
}
