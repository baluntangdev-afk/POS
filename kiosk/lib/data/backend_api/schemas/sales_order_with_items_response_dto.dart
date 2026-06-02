import 'package:dart_mappable/dart_mappable.dart';

import '../enums/sales_order_type.dart';
import '../mappers/date_time_with_offset_mapper.dart';
import 'sales_order_item_response_dto.dart';

part 'sales_order_with_items_response_dto.mapper.dart';

@MappableClass(includeCustomMappers: [DateTimeWithOffsetMapper()])
class SalesOrderWithItemsResponseDto with SalesOrderWithItemsResponseDtoMappable {
  const SalesOrderWithItemsResponseDto({
    required this.id,
    required this.soNumber,
    required this.soDate,
    required this.soType,
    required this.status,
    required this.discountRate,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.finalTotalAmount,
    required this.createdBy,
    required this.salesOrderItems,
    this.totalRefundAmount = 0,
    this.voidReason,
    this.voidedAt,
  });

  final String id;
  final String soNumber;
  final DateTime soDate;
  final SalesOrderType soType;
  final String status;
  final double discountRate;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final double finalTotalAmount;
  final int createdBy;
  final double totalRefundAmount;
  final List<SalesOrderItemResponseDto> salesOrderItems;
  final String? voidReason;
  final DateTime? voidedAt;

  static const fromJson = SalesOrderWithItemsResponseDtoMapper.fromJson;
}
