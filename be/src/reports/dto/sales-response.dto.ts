import { ApiProperty } from '@nestjs/swagger';

/**
 * Response DTO for sales report.
 */
export class SalesResponseDto {
  @ApiProperty({
    description: 'Total of sales order final_total_amount',
    example: 200.0,
  })
  totalSales: number;

  @ApiProperty({
    description: 'Total of sales order discount_amount',
    example: 100.0,
  })
  totalDiscount: number;

  @ApiProperty({
    description: 'Total refunds.',
    example: 0.0,
  })
  totalRefunds: number;

  @ApiProperty({
    description: 'Sales order item count',
    example: 200,
  })
  totalItems: number;

  @ApiProperty({
    description: 'Sales order count',
    example: 20,
  })
  totalTransactions: number;
}
