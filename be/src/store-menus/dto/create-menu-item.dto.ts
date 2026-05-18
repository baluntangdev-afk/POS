import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsBoolean,
  IsArray,
  MaxLength,
  Min,
  Max,
} from 'class-validator';

/**
 * DTO for creating a new menu item.
 */
export class CreateMenuItemDto {
  @ApiPropertyOptional({ type: () => Number, description: 'Product variant ID' })
  @IsOptional()
  @IsNumber()
  productVariantId?: number;

  @ApiProperty({ type: () => String, description: 'Display price', example: '12.99' })
  @IsNotEmpty()
  @IsString()
  displayPrice: string;

  @ApiProperty({ type: () => String, description: 'Category', example: 'Beverages' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(50)
  category: string;

  @ApiPropertyOptional({ type: () => Number, description: 'Display order', example: 1, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9999)
  displayOrder?: number;

  @ApiPropertyOptional({ type: () => Boolean, description: 'Is available', default: true })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({
    type: () => [Number],
    description: 'Array of modifier group IDs to associate with this menu item',
    example: [1, 2, 3],
  })
  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  modifierGroupIds?: number[];
}
