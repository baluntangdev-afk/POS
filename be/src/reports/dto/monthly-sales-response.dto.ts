import { ApiProperty } from '@nestjs/swagger';

/**
 * One month/row in the monthly sales report.
 */
export class MonthlySalesDataItemDto {
  @ApiProperty({
    description: 'Month name (e.g. December, January)',
    example: 'December',
  })
  month: string;

  @ApiProperty({
    description: 'Year (e.g. 2025)',
    example: '2025',
  })
  year: string;

  @ApiProperty({
    description: 'Total of so.final_total_amount for the month',
    example: 5000,
  })
  total: number;

  @ApiProperty({
    description: 'Number of sales orders',
    example: 500,
  })
  transactions: number;

  @ApiProperty({
    description: 'Number of sales order items',
    example: 2000,
  })
  items: number;

  @ApiProperty({
    description: 'Total of so.discount_amount for the month',
    example: 1000,
  })
  discount: number;
}
