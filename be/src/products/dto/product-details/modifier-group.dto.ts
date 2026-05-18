import { ApiProperty, ApiSchema } from '@nestjs/swagger';
import { ModifierOptionDto } from './modifier-options.dto';

@ApiSchema({ name: 'MenuItemModifierGroupDto' })
export class ModifierGroupDto {
  @ApiProperty({ description: 'Modifier group ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Menu item modifier ID', example: 1 })
  menuItemModifierId: number;

  @ApiProperty({ description: 'Modifier group name', example: 'Add-Ons' })
  name: string;

  @ApiProperty({ description: 'Minimum selection', example: 1 })
  minSelection: number;

  @ApiProperty({ description: 'Maximum selection', example: 1 })
  maxSelection: number;

  @ApiProperty({ type: () => [ModifierOptionDto] })
  options: ModifierOptionDto[];
}
