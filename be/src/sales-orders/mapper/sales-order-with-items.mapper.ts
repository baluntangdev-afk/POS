import { SalesOrder } from '../entities/sales-order.entity';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import {
  SalesOrderWithItemsResponseDto,
  SalesOrderItemResponseDto,
} from '../dto/sales-order-with-items-response.dto';

export class SalesOrderWithItemsMapper {
  /**
   * Maps a SalesOrder entity (with salesOrderItems loaded) to the API response DTO.
   */
  static toResponse(salesOrder: SalesOrder, totalRefundAmount = 0): SalesOrderWithItemsResponseDto {
    return {
      id: salesOrder.id,
      soNumber: salesOrder.soNumber,
      soDate: salesOrder.soDate,
      soType: salesOrder.soType,
      status: salesOrder.status,
      discountRate: parseFloat(salesOrder.discountRate ?? '0'),
      discountAmount: parseFloat(salesOrder.discountAmount),
      taxRate: parseFloat(salesOrder.taxRate),
      taxAmount: parseFloat(salesOrder.taxAmount),
      totalAmount: parseFloat(salesOrder.totalAmount),
      finalTotalAmount: parseFloat(salesOrder.finalTotalAmount),
      createdBy: salesOrder.createdBy.id,
      totalRefundAmount,
      voidReason: salesOrder.voidReason ?? null,
      voidedAt: salesOrder.voidedAt ?? null,
      salesOrderItems: salesOrder.salesOrderItems.map(SalesOrderWithItemsMapper.toItemResponse),
    };
  }

  private static toItemResponse(item: SalesOrderItem): SalesOrderItemResponseDto {
    return {
      id: item.id,
      itemSequence: item.itemSequence,
      productVariantId: item.productVariant?.id ?? null,
      recipeId: item.recipe?.id ?? null,
      qty: item.qty,
      uomId: item.uom?.id ?? null,
      unitPrice: parseFloat(item.unitPrice),
      itemDiscountRate: parseFloat(item.itemDiscountRate ?? '0'),
      itemDiscountedPrice: parseFloat(item.itemDiscountedPrice ?? '0'),
      vatExclusiveAmount: parseFloat(item.vatExclusiveAmount ?? '0'),
      vatAmount: parseFloat(item.vatAmount ?? '0'),
      itemSubtotal: parseFloat(item.itemSubtotal),
      itemTotalAmount: parseFloat(item.itemTotalAmount),
      status: item.status,
      description: item.description,
      addOn: item.addOn,
      recipeItemId: item.recipeItem?.id ?? null,
    };
  }
}
