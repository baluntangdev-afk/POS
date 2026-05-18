import 'package:dart_mappable/dart_mappable.dart';

import '../enums/sales_order_type.dart';
import 'create_sales_order_item_dto.dart';

part 'create_sales_order_dto.mapper.dart';

@MappableClass()
class CreateSalesOrderDto with CreateSalesOrderDtoMappable {
  const CreateSalesOrderDto({required this.soType, required this.products});

  final SalesOrderType soType;
  final List<CreateSalesOrderItemDto> products;

  static const fromJson = CreateSalesOrderDtoMapper.fromJson;
}
