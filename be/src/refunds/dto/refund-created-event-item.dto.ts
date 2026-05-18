/**
 * Shape of one item in the RefundCreatedEvent payload.
 */
export interface RefundCreatedEventItemDto {
  refundItemId: number;
  salesOrderItemId: string;
  quantity: number;
  refundAmount: number;
  restockInventory: boolean;
}
