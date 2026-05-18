import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { StoreMenu } from '../entities/store-menu.entity';
import { EntityHelper } from '../../utils/entity.helper';

@Injectable()
export class DeleteStoreMenuService {
  constructor(
    @InjectRepository(StoreMenu)
    private readonly storeMenusRepository: Repository<StoreMenu>,
  ) {}

  async execute(id: number, causer: User): Promise<void> {
    const payload: Partial<StoreMenu> = { deletedBy: causer };
    await this.storeMenusRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.storeMenusRepository.softDelete(id);
  }
}
