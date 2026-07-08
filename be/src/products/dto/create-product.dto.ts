import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';
import { Transform, Type } from 'class-transformer';

/**
 * DTO for creating a new product.
 */
export class CreateProductDto {
  @ApiProperty({ description: 'Product group ID', example: 1 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  groupId: number;

  @ApiProperty({ type: () => String, example: 'Sinigang' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ type: () => String })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Whether the product is available for ordering',
    example: true,
    default: true,
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value === 'true' : value))
  @IsBoolean()
  isAvailable?: boolean;
}
