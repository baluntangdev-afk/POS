import 'package:dart_mappable/dart_mappable.dart';

part 'sales_order_item_response_dto.mapper.dart';

@MappableClass()
class SalesOrderItemResponseDto with SalesOrderItemResponseDtoMappable {
  const SalesOrderItemResponseDto({
    required this.id,
    this.itemSequence,
    this.productVariantId,
    this.recipeId,
    required this.qty,
    this.uomId,
    required this.unitPrice,
    required this.itemDiscountRate,
    this.itemDiscountedPrice,
    required this.vatExclusiveAmount,
    this.vatAmount,
    required this.itemSubtotal,
    required this.itemTotalAmount,
    required this.status,
    required this.description,
    required this.addOn,
    this.recipeItemId,
  });

  final String id;
  final int? itemSequence;
  final int? productVariantId;
  final int? recipeId;
  final String qty;
  final int? uomId;
  final double unitPrice;
  final double itemDiscountRate;
  final double? itemDiscountedPrice;
  final double vatExclusiveAmount;
  final double? vatAmount;
  final double itemSubtotal;
  final double itemTotalAmount;
  final String status;
  final String description;
  final bool addOn;
  final int? recipeItemId;

  static const fromJson = SalesOrderItemResponseDtoMapper.fromJson;
}
