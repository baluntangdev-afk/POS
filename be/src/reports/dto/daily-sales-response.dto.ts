import { ApiProperty } from '@nestjs/swagger';

/**
 * One day/row in the daily sales report.
 */
export class DailySalesDataItemDto {
  @ApiProperty({
    description: 'Date (e.g. MM/DD/YYYY)',
    example: '02/16/2026',
  })
  date: string;

  @ApiProperty({
    description: 'Total of so.final_total_amount for the day',
    example: 400.0,
  })
  total: number;

  @ApiProperty({
    description: 'Number of sales orders',
    example: 4,
  })
  transactions: number;

  @ApiProperty({
    description: 'Number of sales order items',
    example: 12,
  })
  items: number;

  @ApiProperty({
    description: 'Total of so.discount_amount for the day',
    example: 100.0,
  })
  discount: number;
}
