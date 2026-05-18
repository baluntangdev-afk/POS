import 'package:dart_mappable/dart_mappable.dart';

import 'apply_discount_item_discount_dto.dart';
import 'create_sales_order_modifier_group_dto.dart';

part 'create_sales_order_item_dto.mapper.dart';

@MappableClass()
class CreateSalesOrderItemDto with CreateSalesOrderItemDtoMappable {
  const CreateSalesOrderItemDto({
    required this.productVariantId,
    required this.quantity,
    required this.price,
    required this.modifierGroups,
    this.discount,
  });

  final int productVariantId;
  final int quantity;
  final double price;
  final List<CreateSalesOrderModifierGroupDto> modifierGroups;
  final ApplyDiscountItemDiscountDto? discount;

  static const fromJson = CreateSalesOrderItemDtoMapper.fromJson;
}
