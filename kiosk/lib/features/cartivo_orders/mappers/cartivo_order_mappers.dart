import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../data/backend_api/schemas/cartivo_order_dto.dart';
import '../../../data/backend_api/schemas/cartivo_order_item_dto.dart';
import '../entities/cartivo_order.dart';
import '../entities/cartivo_order_item.dart';
import '../entities/cartivo_order_status.dart';

extension CartivoOrderDtoMapper on CartivoOrderDto {
  CartivoOrder get toEntity => CartivoOrder(
    id: id,
    status: CartivoOrderStatus.fromValue(status),
    total: total / 100,
    currency: currency,
    createdAt: createdAt,
    updatedAt: updatedAt,
    items: (items ?? const []).map((item) => item.toEntity).toIList(),
  );
}

extension CartivoOrderItemDtoMapper on CartivoOrderItemDto {
  CartivoOrderItem get toEntity => CartivoOrderItem(
    productId: productId,
    productName: productName,
    quantity: quantity,
    price: price / 100,
  );
}
