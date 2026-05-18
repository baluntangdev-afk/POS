import 'package:dart_mappable/dart_mappable.dart';

import 'refund_item_response_dto.dart';

part 'refund_with_items_response_dto.mapper.dart';

@MappableClass(discriminatorKey: 'paymentMethod')
sealed class RefundWithItemsResponseDto with RefundWithItemsResponseDtoMappable {
  const RefundWithItemsResponseDto({
    required this.id,
    required this.refundNumber,
    required this.reason,
    required this.totalRefundAmount,
    required this.refundDate,
    required this.refundItems,
  });

  final int id;
  final String refundNumber;
  final String reason;
  final double totalRefundAmount;
  final DateTime refundDate;
  final List<RefundItemResponseDto> refundItems;

  static const fromJson = RefundWithItemsResponseDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'Cash')
class CashRefundDto extends RefundWithItemsResponseDto with CashRefundDtoMappable {
  const CashRefundDto({
    required super.id,
    required super.refundNumber,
    required super.reason,
    required super.totalRefundAmount,
    required super.refundDate,
    required super.refundItems,
  });

  static const fromJson = CashRefundDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'Credit Card')
class CreditCardRefundDto extends RefundWithItemsResponseDto with CreditCardRefundDtoMappable {
  const CreditCardRefundDto({
    required super.id,
    required super.refundNumber,
    required super.reason,
    required super.totalRefundAmount,
    required super.refundDate,
    required super.refundItems,
    this.transactionReference = '',
  });

  final String transactionReference;

  static const fromJson = CreditCardRefundDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'GCash')
class GCashRefundDto extends RefundWithItemsResponseDto with GCashRefundDtoMappable {
  const GCashRefundDto({
    required super.id,
    required super.refundNumber,
    required super.reason,
    required super.totalRefundAmount,
    required super.refundDate,
    required super.refundItems,
    this.transactionReference = '',
  });

  final String transactionReference;

  static const fromJson = GCashRefundDtoMapper.fromJson;
}

@MappableClass(discriminatorValue: 'Other')
class OtherRefundDto extends RefundWithItemsResponseDto with OtherRefundDtoMappable {
  const OtherRefundDto({
    required super.id,
    required super.refundNumber,
    required super.reason,
    required super.totalRefundAmount,
    required super.refundDate,
    required super.refundItems,
  });

  static const fromJson = OtherRefundDtoMapper.fromJson;
}
