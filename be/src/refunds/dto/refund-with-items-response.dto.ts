import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';

export class RefundItemResponseDto {
  @ApiProperty({
    description: 'Refund item ID',
    example: 1,
  })
  id: number;

  @ApiProperty({
    description: 'Sales order item ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  salesOrderItemId: string;

  @ApiProperty({ description: 'Quantity', example: 2 })
  quantity: number;

  @ApiProperty({ description: 'Refund amount', example: 59.98 })
  refundAmount: number;

  @ApiProperty({ description: 'Restock inventory flag', example: true })
  restockInventory: boolean;
}

export class RefundWithItemsResponseDto {
  @ApiProperty({
    description: 'Refund ID',
    example: 1,
  })
  id: number;

  @ApiProperty({ description: 'Refund number', example: 'REFUND-001-2026-0001' })
  refundNumber: string;

  @ApiProperty({
    description: 'Refund reason',
    example: 'Wrong order delivered - customer requested different items',
  })
  reason: string;

  @ApiProperty({ description: 'Total refund amount', example: 159.97 })
  totalRefundAmount: number;

  @ApiProperty({
    description: 'Payment method',
    enum: PaymentMethod,
    example: PaymentMethod.CASH,
  })
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({
    description: 'Transaction reference',
    example: 'TXN-123456',
  })
  transactionReference?: string;

  @ApiProperty({ description: 'Refund date', example: '2026-02-20T14:30:00Z' })
  refundDate: Date;

  @ApiProperty({
    description: 'Refund items',
    type: [RefundItemResponseDto],
  })
  refundItems: RefundItemResponseDto[];
}
