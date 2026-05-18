import 'package:dart_mappable/dart_mappable.dart';

part 'create_sales_order_modifier_option_dto.mapper.dart';

@MappableClass()
class CreateSalesOrderModifierOptionDto with CreateSalesOrderModifierOptionDtoMappable {
  const CreateSalesOrderModifierOptionDto({required this.id, required this.priceAddOn});

  final int id;
  final double priceAddOn;

  static const fromJson = CreateSalesOrderModifierOptionDtoMapper.fromJson;
}
