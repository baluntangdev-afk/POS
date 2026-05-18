import 'package:dart_mappable/dart_mappable.dart';

import 'create_sales_order_modifier_option_dto.dart';

part 'create_sales_order_modifier_group_dto.mapper.dart';

@MappableClass()
class CreateSalesOrderModifierGroupDto with CreateSalesOrderModifierGroupDtoMappable {
  const CreateSalesOrderModifierGroupDto({required this.id, required this.modifierOptions});

  final int id;
  final List<CreateSalesOrderModifierOptionDto> modifierOptions;

  static const fromJson = CreateSalesOrderModifierGroupDtoMapper.fromJson;
}
