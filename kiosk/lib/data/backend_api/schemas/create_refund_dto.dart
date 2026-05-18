import 'package:dart_mappable/dart_mappable.dart';

import '../enums/payment_method.dart';
import 'create_refund_item_dto.dart';

part 'create_refund_dto.mapper.dart';

@MappableClass()
class CreateRefundDto with CreateRefundDtoMappable {
  const CreateRefundDto({
    required this.originalSalesOrderId,
    required this.reason,
    required this.totalRefundAmount,
    required this.paymentMethod,
    this.transactionReference,
    required this.refundItems,
  });

  final String originalSalesOrderId;
  final String reason;
  final double totalRefundAmount;
  final PaymentMethod paymentMethod;
  final String? transactionReference;
  final List<CreateRefundItemDto> refundItems;

  static const fromJson = CreateRefundDtoMapper.fromJson;
}
