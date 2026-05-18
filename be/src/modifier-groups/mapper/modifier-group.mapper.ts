import { ModifierGroup } from '../entities/modifier-group.entity';
import { ModifierOption } from '../entities/modifier-option.entity';
import { ModifierGroupDto } from '../dto/modifier-group.dto';

export class ModifierGroupMapper {
  static toModifierGroupDto(
    modifierGroup: ModifierGroup,
    modifierOptions: ModifierOption[],
  ): ModifierGroupDto {
    return {
      id: modifierGroup.id,
      name: modifierGroup.name,
      minSelection: modifierGroup.minSelection,
      maxSelection: modifierGroup.maxSelection,
      modifierOptions: modifierOptions.map((option) => ({
        id: option.id,
        name: option.name,
        priceAddOn: parseFloat(option.priceAddOn.toString()),
        materialId: option.materialId || undefined,
        recipeItemId: option.recipeItemId || undefined,
        imageUrl: option.imageUrl ? option.imageUrl.toString('base64') : undefined,
      })),
    };
  }
}
