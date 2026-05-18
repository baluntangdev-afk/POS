import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, MaxLength, IsBoolean } from 'class-validator';

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

  @ApiProperty({ type: () => Boolean, example: false })
  @IsNotEmpty()
  @IsBoolean()
  isDefault: boolean;
}
