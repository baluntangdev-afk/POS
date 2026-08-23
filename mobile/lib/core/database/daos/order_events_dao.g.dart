// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_events_dao.dart';

// ignore_for_file: type=lint
mixin _$OrderEventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $OrderEventsTableTable get orderEventsTable =>
      attachedDatabase.orderEventsTable;
  OrderEventsDaoManager get managers => OrderEventsDaoManager(this);
}

class OrderEventsDaoManager {
  final _$OrderEventsDaoMixin _db;
  OrderEventsDaoManager(this._db);
  $$OrderEventsTableTableTableManager get orderEventsTable =>
      $$OrderEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.orderEventsTable,
      );
}
