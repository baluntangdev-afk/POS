import 'package:dart_mappable/dart_mappable.dart';

import '../enums/payment_method.dart';

part 'payment_details_dto.mapper.dart';

@MappableClass()
class PaymentDetailsDto with PaymentDetailsDtoMappable {
  const PaymentDetailsDto({
    required this.payeeName,
    required this.method,
    required this.grossAmount,
    required this.taxAmount,
    required this.netAmount,
    required this.amountPaid,
    required this.change,
    this.transactionReference,
  });

  final String payeeName;
  final PaymentMethod method;
  final String grossAmount;
  final String taxAmount;
  final String netAmount;
  final String amountPaid;
  final String change;
  final String? transactionReference;

  static const fromJson = PaymentDetailsDtoMapper.fromJson;
}
