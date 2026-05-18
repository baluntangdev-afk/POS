import '../../../data/backend_api/schemas/sales_data_item_dto.dart';
import '../entities/sales_data_item.dart';

extension DTOMapper on SalesDataItemDto {
  SalesDataItem get toEntity => SalesDataItem(id: id, name: name, totalSales: totalSales);
}

extension EntityMapper on SalesDataItem {
  SalesDataItemDto get toModel => SalesDataItemDto(id: id, name: name, totalSales: totalSales);
}
