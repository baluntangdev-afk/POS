import { Refund } from '../entities/refund.entity';
import { RefundItem } from '../entities/refund-item.entity';
import {
  RefundWithItemsResponseDto,
  RefundItemResponseDto,
} from '../dto/refund-with-items-response.dto';

export class RefundWithItemsMapper {
  /**
   * Maps a Refund entity (with refundItems loaded) to API response DTO.
   */
  static toResponse(refund: Refund): RefundWithItemsResponseDto {
    return {
      id: refund.id,
      refundNumber: refund.refundNumber,
      reason: refund.reason,
      totalRefundAmount: parseFloat(refund.totalRefundAmount),
      paymentMethod: refund.paymentMethod,
      transactionReference: refund.transactionReference || undefined,
      refundDate: refund.refundDate,
      refundItems: refund.refundItems.map(RefundWithItemsMapper.toItemResponse),
    };
  }

  private static toItemResponse(item: RefundItem): RefundItemResponseDto {
    return {
      id: item.id,
      salesOrderItemId: item.salesOrderItem.id,
      quantity: item.quantity,
      refundAmount: parseFloat(item.refundAmount),
      restockInventory: item.restockInventory,
    };
  }
}
