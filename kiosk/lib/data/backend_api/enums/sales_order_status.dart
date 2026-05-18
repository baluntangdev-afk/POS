import 'package:dart_mappable/dart_mappable.dart';

part 'sales_order_status.mapper.dart';

@MappableEnum(mode: ValuesMode.indexed)
enum SalesOrderStatus {
  @MappableValue('Pending')
  pending,

  @MappableValue('Confirmed')
  confirmed,

  @MappableValue('Preparing')
  preparing,

  @MappableValue('Ready')
  ready,

  @MappableValue('Completed')
  completed,

  @MappableValue('Cancelled')
  cancelled,
}
