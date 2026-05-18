import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { UpdateMenuItemDto } from '../dto/update-menu-item.dto';
import { MenuItem } from '../entities/menu-item.entity';
import { MenuItemModifier } from '../entities/menu-item-modifier.entity';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';

@Injectable()
export class UpdateMenuItemService {
  constructor(
    @InjectRepository(MenuItem)
    private readonly menuItemsRepository: Repository<MenuItem>,
    @InjectRepository(MenuItemModifier)
    private readonly menuItemModifiersRepository: Repository<MenuItemModifier>,
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupsRepository: Repository<ModifierGroup>,
  ) {}

  async execute(id: number, updateMenuItemDto: UpdateMenuItemDto): Promise<void> {
    const menuItem = await this.menuItemsRepository.findOne({
      where: { id },
      relations: ['storeMenu'],
    });

    if (!menuItem) {
      throw new NotFoundException('Menu item not found');
    }

    if (menuItem.storeMenu.name !== 'DEFAULT') {
      throw new NotFoundException('Menu item must belong to default store menu');
    }

    const updatePayload = {
      displayPrice: updateMenuItemDto.displayPrice,
      category: updateMenuItemDto.category,
      displayOrder: updateMenuItemDto.displayOrder,
      isAvailable: updateMenuItemDto.isAvailable,
      productVariantId: updateMenuItemDto.productVariantId,
    };

    await this.menuItemsRepository.update(id, updatePayload);

    if (updateMenuItemDto.modifierGroupIds !== undefined) {
      await this.updateMenuItemModifiers(id, updateMenuItemDto.modifierGroupIds);
    }
  }

  private async updateMenuItemModifiers(
    menuItemId: number,
    modifierGroupIds: number[],
  ): Promise<void> {
    const existingModifierGroups = await this.modifierGroupsRepository.findBy({
      id: In(modifierGroupIds),
    });

    if (existingModifierGroups.length !== modifierGroupIds.length) {
      const foundIds = existingModifierGroups.map((group) => group.id);
      const missingIds = modifierGroupIds.filter((id) => !foundIds.includes(id));
      throw new Error(`Modifier groups not found: ${missingIds.join(', ')}`);
    }

    await this.menuItemModifiersRepository.delete({
      menuItem: { id: menuItemId },
    });

    if (modifierGroupIds.length > 0) {
      const menuItemModifiers = modifierGroupIds.map((modifierGroupId) => {
        const menuItemModifier = this.menuItemModifiersRepository.create({
          menuItem: { id: menuItemId },
          modifierGroup: { id: modifierGroupId },
        });
        return menuItemModifier;
      });

      await this.menuItemModifiersRepository.save(menuItemModifiers);
    }
  }
}
