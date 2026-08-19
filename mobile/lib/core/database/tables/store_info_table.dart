import 'package:drift/drift.dart';

class StoreInfoTable extends Table {
  @override
  String get tableName => 'store_info';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeId => text().withDefault(const Constant(''))();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('PHP'))();
  TextColumn get receiptFooter => text().withDefault(const Constant(''))();
  TextColumn get tin => text().withDefault(const Constant(''))();
  TextColumn get terminalName => text().withDefault(const Constant(''))();
}
