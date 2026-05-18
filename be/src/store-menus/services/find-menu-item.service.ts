import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from '../entities/menu-item.entity';
import { MenuItemDto } from '../dto/menu-item.dto';
import { MenuItemMapper } from '../mapper/menu-item.mapper';

@Injectable()
export class FindMenuItemService {
  constructor(
    @InjectRepository(MenuItem)
    private readonly menuItemsRepository: Repository<MenuItem>,
  ) {}

  async execute(id: number): Promise<MenuItemDto> {
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
      throw new NotFoundException('Menu item not found');
    }

    if (menuItem.storeMenu.name !== 'DEFAULT') {
      throw new NotFoundException('Menu item must belong to default store menu');
    }

    return MenuItemMapper.toMenuItemDto(menuItem);
  }
}
