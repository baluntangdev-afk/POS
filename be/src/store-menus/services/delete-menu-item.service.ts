import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from '../entities/menu-item.entity';

@Injectable()
export class DeleteMenuItemService {
  constructor(
    @InjectRepository(MenuItem)
    private readonly menuItemsRepository: Repository<MenuItem>,
  ) {}

  async execute(id: number): Promise<void> {
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

    await this.menuItemsRepository.softDelete(id);
  }
}
