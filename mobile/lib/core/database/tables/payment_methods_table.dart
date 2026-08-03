import 'package:drift/drift.dart';

class PaymentMethodsTable extends Table {
  @override
  String get tableName => 'payment_methods';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 100)();
  TextColumn get accountName => text().nullable()();
  TextColumn get accountNumber => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
