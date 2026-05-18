import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateStoreMenuDto } from '../dto/create-store-menu.dto';
import { User } from '../../users/entities/user.entity';
import { StoreMenu } from '../entities/store-menu.entity';
import { StoreMenuDto } from '../dto/store-menu.dto';
import { StoreMenuMapper } from '../mapper/store-menu.mapper';

@Injectable()
export class CreateStoreMenuService {
  constructor(
    @InjectRepository(StoreMenu)
    private readonly storeMenusRepository: Repository<StoreMenu>,
  ) {}

  async execute(createStoreMenuDto: CreateStoreMenuDto, causer: User): Promise<StoreMenuDto> {
    const payload: Partial<StoreMenu> = {
      name: createStoreMenuDto.name,
      description: createStoreMenuDto.description,
      status: createStoreMenuDto.status,
      createdBy: causer,
      updatedBy: causer,
    };

    const entity = this.storeMenusRepository.create(payload);
    const result = await this.storeMenusRepository.save(entity);

    return StoreMenuMapper.toStoreMenuDto(result);
  }
}
