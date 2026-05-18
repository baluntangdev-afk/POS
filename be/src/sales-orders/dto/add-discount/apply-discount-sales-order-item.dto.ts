import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsNumber, IsObject, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApplyDiscountItemDiscountDto } from './apply-discount-item-discount.dto';

/**
 * Sales order item with discounts for apply-discount payload.
 */
export class ApplyDiscountSalesOrderItemDto {
  @ApiProperty({
    description: 'Sales order item ID',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @IsString()
  id: string;

  @ApiProperty({ description: 'Item sequence', example: 1 })
  @IsNumber()
  @Type(() => Number)
  itemSequence: number;

  @ApiProperty({ description: 'Quantity', example: 3 })
  @IsNumber()
  @Type(() => Number)
  qty: number;

  @ApiProperty({ description: 'Unit price', example: 100 })
  @IsNumber()
  @Type(() => Number)
  unitPrice: number;

  @ApiProperty({ description: 'Item discount rate', example: 0 })
  @IsNumber()
  @Type(() => Number)
  itemDiscountRate: number;

  @ApiProperty({ description: 'Item discounted price', example: 0 })
  @IsNumber()
  @Type(() => Number)
  itemDiscountedPrice: number;

  @ApiProperty({ description: 'Item total amount', example: 100 })
  @IsNumber()
  @Type(() => Number)
  itemTotalAmount: number;

  @ApiProperty({ description: 'Line status', example: 'Draft' })
  @IsString()
  status: string;

  @ApiProperty({ description: 'Line description', example: 'Chicken Panini' })
  @IsString()
  description: string;

  @ApiProperty({ description: 'Whether line is add-on', example: false })
  @IsBoolean()
  @Type(() => Boolean)
  addOn: boolean;

  @ApiProperty({
    type: () => ApplyDiscountItemDiscountDto,
    description: 'Discount applied to this item',
  })
  @IsObject()
  @ValidateNested()
  @Type(() => ApplyDiscountItemDiscountDto)
  discounts: ApplyDiscountItemDiscountDto;
}
