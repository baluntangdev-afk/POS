import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * DTO for creating a new product group.
 */
export class CreateProductGroupDto {
  @ApiProperty({
    description: 'Product group name (e.g. Beverages, Dessert, Meals)',
    example: 'Beverages',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ description: 'Detailed item description' })
  @IsOptional()
  @IsString()
  description?: string;
}
