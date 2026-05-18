import 'package:dart_mappable/dart_mappable.dart';

part 'payment_response_dto.mapper.dart';

@MappableClass(discriminatorKey: 'paymentMethod')
sealed class PaymentResponseDto with PaymentResponseDtoMappable {
  const PaymentResponseDto({required this.id});

  final String id;

  static const fromJson = PaymentResponseDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'Cash')
class CashPaymentDto extends PaymentResponseDto with CashPaymentDtoMappable {
  const CashPaymentDto({required super.id, required this.amountPaid, required this.change});

  final String amountPaid;
  final String change;

  static const fromJson = CashPaymentDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'Credit Card')
class CreditCardPaymentDto extends PaymentResponseDto with CreditCardPaymentDtoMappable {
  const CreditCardPaymentDto({
    required super.id,
    required this.amountPaid,
    this.transactionReference = '',
  });

  final String amountPaid;
  final String transactionReference;

  static const fromJson = CreditCardPaymentDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'GCash')
class GCashPaymentDto extends PaymentResponseDto with GCashPaymentDtoMappable {
  const GCashPaymentDto({
    required super.id,
    required this.amountPaid,
    this.transactionReference = '',
  });

  final String amountPaid;
  final String transactionReference;

  static const fromJson = GCashPaymentDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'Other')
class OtherPaymentDto extends PaymentResponseDto with OtherPaymentDtoMappable {
  const OtherPaymentDto({required super.id, required this.amountPaid});

  final String amountPaid;

  static const fromJson = OtherPaymentDtoMapper.fromJson;
}
