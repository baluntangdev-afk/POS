import 'package:dart_mappable/dart_mappable.dart';

part 'sales_order_type.mapper.dart';

@MappableEnum(mode: ValuesMode.indexed)
enum SalesOrderType {
  @MappableValue('Dine-In')
  dineIn,

  @MappableValue('Take-Out')
  takeOut,

  @MappableValue('Delivery')
  delivery,
}
