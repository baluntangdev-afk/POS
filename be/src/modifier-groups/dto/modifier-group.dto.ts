import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Modifier Option DTO.
 */
export class ModifierOptionDto {
  @ApiProperty({ description: 'Modifier option ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Modifier option name', example: 'Extra Cheese' })
  name: string;

  @ApiProperty({ description: 'Additional price', example: 1.5 })
  priceAddOn: number;

  @ApiPropertyOptional({ description: 'Material ID', example: 1 })
  materialId?: number;

  @ApiPropertyOptional({ description: 'Recipe item ID', example: 1 })
  recipeItemId?: number;

  @ApiPropertyOptional({ description: 'Image URL (base64)', example: 'base64-image-data' })
  imageUrl?: string;
}

/**
 * Modifier Group DTO.
 */
export class ModifierGroupDto {
  @ApiProperty({ description: 'Modifier group ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Modifier group name', example: 'Extra Toppings' })
  name: string;

  @ApiProperty({ description: 'Minimum number of selections required', example: 0 })
  minSelection: number;

  @ApiProperty({ description: 'Maximum number of selections allowed', example: 3 })
  maxSelection: number;

  @ApiProperty({
    type: () => [ModifierOptionDto],
    description: 'List of modifier options for this group',
  })
  modifierOptions: ModifierOptionDto[];
}
