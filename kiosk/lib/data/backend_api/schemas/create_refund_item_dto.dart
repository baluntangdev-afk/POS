import 'package:dart_mappable/dart_mappable.dart';

part 'create_refund_item_dto.mapper.dart';

@MappableClass()
class CreateRefundItemDto with CreateRefundItemDtoMappable {
  const CreateRefundItemDto({
    required this.salesOrderItemId,
    required this.quantity,
    required this.refundAmount,
    this.restockInventory = false,
  });

  final String salesOrderItemId;
  final int quantity;
  final double refundAmount;
  final bool restockInventory;

  static const fromJson = CreateRefundItemDtoMapper.fromJson;
}
