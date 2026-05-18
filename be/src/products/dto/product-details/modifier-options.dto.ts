import { ApiProperty, ApiSchema } from '@nestjs/swagger';

@ApiSchema({ name: 'MenuItemModifierOptionDto' })
export class ModifierOptionDto {
  @ApiProperty({ description: 'Modifier option ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Modifier option name', example: 'Muffin' })
  name: string;

  @ApiProperty({ description: 'Price add-on', example: '100' })
  priceAddOn: string;

  @ApiProperty({ description: 'Material ID', example: 1 })
  materialId: number | null;

  @ApiProperty({ description: 'Recipe item ID', example: 1 })
  recipeItemId: number | null;

  @ApiProperty({ description: 'Image URL', example: 'https://example.com/image.jpg' })
  imageUrl: string | null;

  @ApiProperty({ description: 'Selected', example: true })
  isSelected?: boolean;
}
