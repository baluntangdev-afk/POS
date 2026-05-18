import { ApiProperty } from '@nestjs/swagger';

/**
 * One product row in the product sales report.
 */
export class ProductSalesDataItemDto {
  @ApiProperty({ description: 'Product id', example: 2 })
  id: number;

  @ApiProperty({ description: 'Product name', example: 'Fries' })
  name: string;

  @ApiProperty({ description: 'Total sales for this product in the period', example: 700 })
  totalSales: number;
}
