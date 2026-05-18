import 'package:dart_mappable/dart_mappable.dart';

import '../enums/sales_data_item_type.dart';

part 'sales_data_item.mapper.dart';

@MappableClass()
class SalesDataItem with SalesDataItemMappable {
  const SalesDataItem({
    required this.id,
    required this.name,
    required this.totalSales,
    this.type = SalesDataItemType.productGroup,
  });

  final int id;
  final String name;
  final double totalSales;
  final SalesDataItemType type;
}
