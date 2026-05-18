import { ApiProperty } from '@nestjs/swagger';

/**
 * One product group row in the product group sales report.
 */
export class ProductGroupSalesDataItemDto {
  @ApiProperty({ description: 'Product group id', example: 2 })
  id: number;

  @ApiProperty({ description: 'Product group name', example: 'Meals' })
  name: string;

  @ApiProperty({ description: 'Total sales for this product group in the period', example: 700 })
  totalSales: number;
}
