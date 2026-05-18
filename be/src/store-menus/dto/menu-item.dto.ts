import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Menu Item DTO.
 */
export class MenuItemDto {
  @ApiProperty({ description: 'Menu item ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Store menu ID', example: 1 })
  storeMenuId: number;

  @ApiPropertyOptional({ description: 'Product variant ID', example: 1 })
  productVariantId?: number;

  @ApiProperty({ description: 'Display price', example: '12.99' })
  displayPrice: string;

  @ApiProperty({ description: 'Category', example: 'Beverages' })
  category: string;

  @ApiProperty({ description: 'Display order', example: 1 })
  displayOrder: number;

  @ApiProperty({ description: 'Is available', example: true })
  isAvailable: boolean;

  @ApiPropertyOptional({
    description: 'Modifier groups associated with this menu item',
    type: () => [ModifierGroupDto],
  })
  modifierGroups?: ModifierGroupDto[];
}

/**
 * Modifier Group DTO for menu items.
 */
export class ModifierGroupDto {
  @ApiProperty({ description: 'Modifier group ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Modifier group name', example: 'Extra Toppings' })
  name: string;

  @ApiProperty({ description: 'Minimum selections required', example: 0 })
  minSelection: number;

  @ApiProperty({ description: 'Maximum selections allowed', example: 3 })
  maxSelection: number;
}
