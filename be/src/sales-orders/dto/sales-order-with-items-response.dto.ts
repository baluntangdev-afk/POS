import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Response shape for a single sales order item.
 */
export class SalesOrderItemResponseDto {
  @ApiProperty({
    description: 'Sales order item ID',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  id: string;

  @ApiPropertyOptional({ description: 'Line item sequence', example: 1, nullable: true })
  itemSequence: number | null;

  @ApiPropertyOptional({ description: 'Product variant ID', example: 1, nullable: true })
  productVariantId: number | null;

  @ApiPropertyOptional({ description: 'Recipe ID', example: 1, nullable: true })
  recipeId: number | null;

  @ApiProperty({ description: 'Quantity', example: '1' })
  qty: string;

  @ApiPropertyOptional({ description: 'Unit of measure ID', example: 1, nullable: true })
  uomId: number | null;

  @ApiProperty({ description: 'Unit price', example: 100 })
  unitPrice: number;

  @ApiProperty({ description: 'Item discount rate (percent)', example: 0 })
  itemDiscountRate: number;

  @ApiPropertyOptional({ description: 'Item discounted price', example: 0, nullable: true })
  itemDiscountedPrice: number | null;

  @ApiProperty({ description: 'VAT exclusive amount', example: 100 })
  vatExclusiveAmount: number;

  @ApiPropertyOptional({ description: 'VAT amount', example: 0, nullable: true })
  vatAmount: number | null;

  @ApiProperty({ description: 'Item subtotal', example: 100 })
  itemSubtotal: number;

  @ApiProperty({ description: 'Item total amount', example: 100 })
  itemTotalAmount: number;

  @ApiProperty({ description: 'Line item status', example: 'Pending' })
  status: string;

  @ApiProperty({ description: 'Product summary description', example: 'Small Burger' })
  description: string;

  @ApiProperty({ description: 'Whether this line is an add-on', example: false })
  addOn: boolean;

  @ApiPropertyOptional({ description: 'Recipe item ID when add-on', example: null, nullable: true })
  recipeItemId: number | null;

  @ApiPropertyOptional({
    description: 'Sale type for this item',
    example: 'Dine-In',
    nullable: true,
  })
  saleType: string | null;

  @ApiPropertyOptional({ description: 'Item-level note', example: 'No onions please', nullable: true })
  note: string | null;
}

/**
 * Response shape for a sales order with items.
 */
export class SalesOrderWithItemsResponseDto {
  @ApiProperty({
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  id: string;

  @ApiProperty({ description: 'Sales order number', example: 'SO-001-2026-0001' })
  soNumber: string;

  @ApiProperty({ description: 'Sales order date', example: '2026-02-25T13:55:00Z' })
  soDate: Date;

  @ApiProperty({
    description: 'Order type',
    example: 'Dine-In',
    enum: ['Dine-In', 'Take-Out', 'Delivery'],
  })
  soType: string;

  @ApiProperty({ description: 'Order status', example: 'Pending' })
  status: string;

  @ApiProperty({ description: 'Discount rate (percent)', example: 0 })
  discountRate: number;

  @ApiProperty({ description: 'Discount amount', example: 0 })
  discountAmount: number;

  @ApiProperty({ description: 'Tax rate (percent)', example: 12 })
  taxRate: number;

  @ApiProperty({ description: 'Tax amount', example: 39.6 })
  taxAmount: number;

  @ApiProperty({ description: 'Total amount before tax', example: 330 })
  totalAmount: number;

  @ApiProperty({ description: 'Final total amount including tax', example: 369.6 })
  finalTotalAmount: number;

  @ApiProperty({ description: 'Created by user ID', example: 1 })
  createdBy: number;

  @ApiProperty({ description: 'Total amount refunded across all refunds', example: 0 })
  totalRefundAmount: number;

  @ApiPropertyOptional({ description: 'Void reason', nullable: true, example: null })
  voidReason: string | null;

  @ApiPropertyOptional({ description: 'Voided at timestamp', nullable: true, example: null })
  voidedAt: Date | null;

  @ApiProperty({
    description: 'Sales order line items',
    type: [SalesOrderItemResponseDto],
  })
  salesOrderItems: SalesOrderItemResponseDto[];
}
