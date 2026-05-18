import { ApiProperty } from '@nestjs/swagger';

/**
 * One hour/row in the hourly sales report.
 */
export class HourlySalesDataItemDto {
  @ApiProperty({
    description: 'Date (e.g. MM/DD/YYYY)',
    example: '02/16/2026',
  })
  date: string;

  @ApiProperty({
    description: 'Hour (e.g. 01:00 PM)',
    example: '01:00 PM',
  })
  hour: string;

  @ApiProperty({
    description: 'Total of so.final_total_amount for the hour',
    example: 200.0,
  })
  total: number;

  @ApiProperty({
    description: 'Number of sales orders',
    example: 2,
  })
  transactions: number;

  @ApiProperty({
    description: 'Number of sales order items',
    example: 6,
  })
  items: number;

  @ApiProperty({
    description: 'Total of so.discount_amount for the hour',
    example: 50.0,
  })
  discount: number;
}
