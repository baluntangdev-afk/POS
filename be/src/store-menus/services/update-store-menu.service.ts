import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateStoreMenuDto } from '../dto/update-store-menu.dto';
import { StoreMenu } from '../entities/store-menu.entity';
import { EntityHelper } from '../../utils/entity.helper';
import { User } from '../../users/entities/user.entity';

@Injectable()
export class UpdateStoreMenuService {
  constructor(
    @InjectRepository(StoreMenu)
    private readonly storeMenusRepository: Repository<StoreMenu>,
  ) {}

  async execute(id: number, updateStoreMenuDto: UpdateStoreMenuDto, causer: User): Promise<void> {
    const payload: Partial<StoreMenu> = {
      name: updateStoreMenuDto.name,
      description: updateStoreMenuDto.description,
      status: updateStoreMenuDto.status,
      updatedBy: causer,
    };
    await this.storeMenusRepository.update(id, EntityHelper.toPartialEntity(payload));
  }
}
