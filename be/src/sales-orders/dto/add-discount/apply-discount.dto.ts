import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApplyDiscountSalesOrderItemDto } from './apply-discount-sales-order-item.dto';

/**
 * DTO for applying discounts to sales order items.
 */
export class ApplyDiscountDto {
  @ApiProperty({
    type: () => [ApplyDiscountSalesOrderItemDto],
    description: 'Sales order items with their applied discounts',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ApplyDiscountSalesOrderItemDto)
  salesOrderItems: ApplyDiscountSalesOrderItemDto[];
}
