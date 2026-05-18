import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Discount applied to a sales order item (e.g. Senior Citizen / PWD).
 */
export class ApplyDiscountItemDiscountDto {
  @ApiProperty({ description: 'Discount ID', example: 1 })
  @IsNumber()
  @Type(() => Number)
  id: number;

  @ApiProperty({ description: 'Discount name', example: 'Senior Citizen / PWD' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Discount value (e.g. percentage)', example: 20 })
  @IsNumber()
  @Type(() => Number)
  value: number;
}
