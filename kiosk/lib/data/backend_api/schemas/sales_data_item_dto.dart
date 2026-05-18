import 'package:dart_mappable/dart_mappable.dart';

part 'sales_data_item_dto.mapper.dart';

@MappableClass()
class SalesDataItemDto with SalesDataItemDtoMappable {
  const SalesDataItemDto({required this.id, required this.name, required this.totalSales});

  final int id;
  final String name;
  final double totalSales;

  static const fromJson = SalesDataItemDtoMapper.fromJson;
}
