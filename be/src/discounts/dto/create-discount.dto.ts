import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { DiscountType, DiscountStatus } from '../discounts.enum';

/**
 * DTO for creating a new discount.
 */
export class CreateDiscountDto {
  @ApiProperty({ description: 'Discount name (e.g. PWD Discount)', example: 'PWD Discount' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiProperty({ enum: DiscountType, description: 'Discount type' })
  @IsNotEmpty()
  @IsEnum(DiscountType)
  type: DiscountType;

  @ApiProperty({ description: 'The % or $ amount to deduct', example: 10 })
  @IsNotEmpty()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  value: number;

  @ApiPropertyOptional({ enum: DiscountStatus, default: DiscountStatus.ACTIVE })
  @IsOptional()
  @IsEnum(DiscountStatus)
  status?: DiscountStatus;
}
