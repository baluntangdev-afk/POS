import 'package:dart_mappable/dart_mappable.dart';

part 'payment_method_entry_dto.mapper.dart';

@MappableClass()
class PaymentMethodEntryDto with PaymentMethodEntryDtoMappable {
  const PaymentMethodEntryDto({
    required this.id,
    required this.paymentMethod,
    this.paymentNumber,
  });

  final int id;
  final String paymentMethod;
  final String? paymentNumber;

  static const fromJson = PaymentMethodEntryDtoMapper.fromJson;
}
