import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { OrderCreatedEventItemDto } from '../dto/order-created-event-item.dto';

export class OrderCreatedEventMapper {
  /**
   * Maps saved sales order items to the payload shape for OrderCreatedEvent.
   */
  static toEventItems(salesOrderItems: SalesOrderItem[]): OrderCreatedEventItemDto[] {
    return salesOrderItems.map((soi) => ({
      soItemId: soi.id,
      productVariantId: soi.productVariant.id,
      recipeId: soi.recipe.id,
      quantity: parseInt(soi.qty, 10),
      recipeItemId: soi.recipeItem?.id,
      isAddOn: soi.addOn,
    }));
  }
}
