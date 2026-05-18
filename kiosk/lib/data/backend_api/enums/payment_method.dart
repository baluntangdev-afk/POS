import 'package:dart_mappable/dart_mappable.dart';

part 'payment_method.mapper.dart';

@MappableEnum(mode: ValuesMode.indexed)
enum PaymentMethod {
  @MappableValue('Cash')
  cash,

  @MappableValue('Credit Card')
  creditCard,

  @MappableValue('GCash')
  gCash,

  @MappableValue('Other')
  other,
}
