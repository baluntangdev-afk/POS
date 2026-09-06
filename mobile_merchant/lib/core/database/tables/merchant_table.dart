import 'package:drift/drift.dart';

class MerchantTable extends Table {
  @override
  String get tableName => 'merchant';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchantId => text()();
  TextColumn get merchantName => text()();
}
