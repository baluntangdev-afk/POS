import 'package:drift/drift.dart';

class CartivoProductsTable extends Table {
  @override
  String get tableName => 'cartivo_products';

  IntColumn get productId => integer()();
  TextColumn get merchantId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}
