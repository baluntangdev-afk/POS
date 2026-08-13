import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../data/backend_api/schemas/replenishment_order_dto.dart';
import '../../../data/backend_api/schemas/replenishment_order_item_dto.dart';
import '../../../data/backend_api/schemas/replenishment_payment_dto.dart';
import '../entities/replenishment_order.dart';
import '../entities/replenishment_order_item.dart';
import '../entities/replenishment_order_status.dart';
import '../entities/replenishment_payment.dart';

extension ReplenishmentOrderDtoMapper on ReplenishmentOrderDto {
  ReplenishmentOrder get toEntity => ReplenishmentOrder(
    id: id,
    customerId: customerId,
    customerName: customerName,
    customerEmail: customerEmail,
    status: ReplenishmentOrderStatus.fromValue(status),
    total: total / 100,
    currency: currency,
    createdAt: createdAt,
    updatedAt: updatedAt,
    items: (items ?? const []).map((item) => item.toEntity).toIList(),
  );
}

extension ReplenishmentOrderItemDtoMapper on ReplenishmentOrderItemDto {
  ReplenishmentOrderItem get toEntity => ReplenishmentOrderItem(
    productId: productId,
    productName: productName,
    quantity: quantity,
    price: price / 100,
  );
}

extension ReplenishmentPaymentDtoMapper on ReplenishmentPaymentDto {
  ReplenishmentPayment get toEntity => ReplenishmentPayment(
    id: id,
    orderId: orderId,
    amount: amount / 100,
    currency: currency,
    status: status,
    createdAt: createdAt,
  );
}
