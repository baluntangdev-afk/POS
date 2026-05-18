import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';

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
}
