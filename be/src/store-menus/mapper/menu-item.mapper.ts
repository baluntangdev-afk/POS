import { MenuItem } from '../entities/menu-item.entity';
import { MenuItemDto, ModifierGroupDto } from '../dto/menu-item.dto';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';

export class MenuItemMapper {
  static toMenuItemDto(entity: MenuItem): MenuItemDto {
    return {
      id: entity.id,
      storeMenuId: entity.storeMenu.id,
      productVariantId: entity.productVariant?.id,
      displayPrice: entity.displayPrice,
      category: entity.category,
      displayOrder: entity.displayOrder,
      isAvailable: entity.isAvailable,
      modifierGroups: entity.menuItemModifiers?.map((modifier) =>
        MenuItemMapper.toModifierGroupDto(modifier.modifierGroup),
      ),
    };
  }

  static toModifierGroupDto(modifierGroup: ModifierGroup): ModifierGroupDto {
    return {
      id: modifierGroup.id,
      name: modifierGroup.name,
      minSelection: modifierGroup.minSelection,
      maxSelection: modifierGroup.maxSelection,
    };
  }
}
