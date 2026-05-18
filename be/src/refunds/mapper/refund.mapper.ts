import { Refund } from '../entities/refund.entity';
import { RefundWithItemsResponseDto } from '../dto/refund-with-items-response.dto';

export class RefundMapper {
  /**
   * Maps a Refund entity to the API response DTO.
   */
  static toResponse(refund: Refund): RefundWithItemsResponseDto {
    return {
      id: refund.id,
      refundNumber: refund.refundNumber,
      reason: refund.reason,
      totalRefundAmount: parseFloat(refund.totalRefundAmount),
      paymentMethod: refund.paymentMethod,
      transactionReference: refund.transactionReference ?? undefined,
      refundDate: refund.refundDate,
      refundItems:
        refund.refundItems?.map((item) => ({
          id: item.id,
          salesOrderItemId: item.salesOrderItem.id,
          quantity: item.quantity,
          refundAmount: parseFloat(item.refundAmount),
          restockInventory: item.restockInventory,
        })) ?? [],
    };
  }
}
