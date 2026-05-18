import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StoreMenu } from '../entities/store-menu.entity';
import { StoreMenuDto } from '../dto/store-menu.dto';
import { StoreMenuMapper } from '../mapper/store-menu.mapper';

@Injectable()
export class FindStoreMenuService {
  constructor(
    @InjectRepository(StoreMenu)
    private readonly storeMenusRepository: Repository<StoreMenu>,
  ) {}

  async execute(id: number): Promise<StoreMenuDto> {
    const storeMenu = await this.storeMenusRepository.findOne({
      where: { id },
      relations: ['createdBy', 'updatedBy'],
    });

    if (!storeMenu) {
      throw new NotFoundException(`Store menu with ID ${id} not found`);
    }

    return StoreMenuMapper.toStoreMenuDto(storeMenu);
  }
}
