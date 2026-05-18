import 'package:dart_mappable/dart_mappable.dart';

part 'refund_item_response_dto.mapper.dart';

@MappableClass()
class RefundItemResponseDto with RefundItemResponseDtoMappable {
  const RefundItemResponseDto({
    required this.id,
    required this.salesOrderItemId,
    required this.quantity,
    required this.refundAmount,
    required this.restockInventory,
  });

  final int id;
  final String salesOrderItemId;
  final int quantity;
  final double refundAmount;
  final bool restockInventory;

  static const fromJson = RefundItemResponseDtoMapper.fromJson;
}
