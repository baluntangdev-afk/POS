import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, MaxLength, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for creating a new product variant.
 */
export class CreateProductVariantDto {
  @ApiProperty({ type: () => Number, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  productId: number;

  @ApiProperty({ type: () => String, example: 'Large' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiProperty({ type: () => Number, example: 150.0 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  price: number;

  @ApiProperty({ type: () => Boolean, example: false })
  @IsNotEmpty()
  @IsBoolean()
  isDefault: boolean;
}
