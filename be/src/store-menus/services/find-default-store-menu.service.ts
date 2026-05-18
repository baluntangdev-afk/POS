import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StoreMenu } from '../entities/store-menu.entity';

@Injectable()
export class FindDefaultStoreMenuService {
  constructor(
    @InjectRepository(StoreMenu)
    private readonly storeMenusRepository: Repository<StoreMenu>,
  ) {}

  async execute(): Promise<StoreMenu> {
    const defaultStoreMenu = await this.storeMenusRepository.findOne({
      where: { name: 'DEFAULT' },
    });

    if (!defaultStoreMenu) {
      throw new NotFoundException('Default store menu not found');
    }

    return defaultStoreMenu;
  }
}
