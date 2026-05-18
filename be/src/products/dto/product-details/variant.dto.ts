import { ApiProperty, ApiSchema } from '@nestjs/swagger';
import { ModifierGroupDto } from './modifier-group.dto';

@ApiSchema({ name: 'ProductVariantDetailsDto' })
export class ProductVariantDto {
  @ApiProperty({ description: 'Product variant ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Product variant name', example: 'Regular' })
  name: string;

  @ApiProperty({ description: 'Display price', example: '100' })
  displayPrice: string;

  @ApiProperty({ description: 'Menu item ID', example: 1 })
  menuItemId: number;

  @ApiProperty({ description: 'Is default', example: true })
  isDefault: boolean;

  @ApiProperty({ description: 'Is selected', example: true })
  isSelected?: boolean;

  @ApiProperty({ type: () => [ModifierGroupDto] })
  modifierGroups: ModifierGroupDto[];
}
