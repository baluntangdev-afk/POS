import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { CreateMenuItemDto } from '../dto/create-menu-item.dto';
import { User } from '../../users/entities/user.entity';
import { MenuItem } from '../entities/menu-item.entity';
import { MenuItemModifier } from '../entities/menu-item-modifier.entity';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { MenuItemDto } from '../dto/menu-item.dto';
import { MenuItemMapper } from '../mapper/menu-item.mapper';
import { FindDefaultStoreMenuService } from './find-default-store-menu.service';

@Injectable()
export class CreateMenuItemService {
  constructor(
    @InjectRepository(MenuItem)
    private readonly menuItemsRepository: Repository<MenuItem>,
    @InjectRepository(MenuItemModifier)
    private readonly menuItemModifiersRepository: Repository<MenuItemModifier>,
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupsRepository: Repository<ModifierGroup>,
    private readonly findDefaultStoreMenuService: FindDefaultStoreMenuService,
  ) {}

  async execute(createMenuItemDto: CreateMenuItemDto, causer: User): Promise<MenuItemDto> {
    const defaultStoreMenu = await this.findDefaultStoreMenuService.execute();

    let productVariant: ProductVariant | null = null;
    if (createMenuItemDto.productVariantId) {
      productVariant = await this.menuItemsRepository.manager.findOne(ProductVariant, {
        where: { id: createMenuItemDto.productVariantId },
      });
      if (!productVariant) {
        throw new Error(`Product variant with ID ${createMenuItemDto.productVariantId} not found`);
      }
    }

    const payload: Partial<MenuItem> = {
      storeMenu: defaultStoreMenu,
      productVariant,
      displayPrice: createMenuItemDto.displayPrice,
      category: createMenuItemDto.category,
      displayOrder: createMenuItemDto.displayOrder || 0,
      isAvailable: createMenuItemDto.isAvailable ?? true,
      createdBy: causer,
      updatedBy: causer,
    };

    const entity = this.menuItemsRepository.create(payload);
    const result = await this.menuItemsRepository.save(entity);

    if (createMenuItemDto.modifierGroupIds && createMenuItemDto.modifierGroupIds.length > 0) {
      await this.createMenuItemModifiers(result.id, createMenuItemDto.modifierGroupIds, causer);
    }

    return this.findMenuItemWithModifiers(result.id);
  }

  private async createMenuItemModifiers(
    menuItemId: number,
    modifierGroupIds: number[],
    causer: User,
  ): Promise<void> {
    const existingModifierGroups = await this.modifierGroupsRepository.findBy({
      id: In(modifierGroupIds),
    });

    if (existingModifierGroups.length !== modifierGroupIds.length) {
      const foundIds = existingModifierGroups.map((group) => group.id);
      const missingIds = modifierGroupIds.filter((id) => !foundIds.includes(id));
      throw new Error(`Modifier groups not found: ${missingIds.join(', ')}`);
    }

    const menuItemModifiers = modifierGroupIds.map((modifierGroupId) => {
      const menuItemModifier = this.menuItemModifiersRepository.create({
        menuItem: { id: menuItemId },
        modifierGroup: { id: modifierGroupId },
        createdBy: causer,
        updatedBy: causer,
      });
      return menuItemModifier;
    });

    await this.menuItemModifiersRepository.save(menuItemModifiers);
  }

  private async findMenuItemWithModifiers(id: number): Promise<MenuItemDto> {
    const menuItem = await this.menuItemsRepository.findOne({
      where: { id },
      relations: [
        'storeMenu',
        'productVariant',
        'menuItemModifiers',
        'menuItemModifiers.modifierGroup',
      ],
    });

    if (!menuItem) {
      throw new Error('Menu item not found after creation');
    }

    return MenuItemMapper.toMenuItemDto(menuItem);
  }
}
