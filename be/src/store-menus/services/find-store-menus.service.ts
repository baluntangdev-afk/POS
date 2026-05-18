import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike, FindOptionsWhere } from 'typeorm';
import { StoreMenu } from '../entities/store-menu.entity';
import { StoreMenuQueryDto } from '../dto/store-menu-query.dto';
import { PaginatedResult, parseSort } from '../../utils/pagination';
import { StoreMenuDto } from '../dto/store-menu.dto';
import { StoreMenuMapper } from '../mapper/store-menu.mapper';

@Injectable()
export class FindStoreMenusService {
  constructor(
    @InjectRepository(StoreMenu)
    private readonly storeMenusRepository: Repository<StoreMenu>,
  ) {}

  async execute(query: StoreMenuQueryDto): Promise<PaginatedResult<StoreMenuDto>> {
    const { page, limit, sort, name, description, status } = query;
    const skip = (page - 1) * limit;

    const STORE_MENU_SORTABLE_FIELDS: (keyof StoreMenu)[] = ['id', 'name', 'createdAt'];
    const order = parseSort<StoreMenu>(sort, {
      allowedFields: STORE_MENU_SORTABLE_FIELDS,
      defaultOrder: { id: 'ASC' },
    });

    const where: FindOptionsWhere<StoreMenu> = {};

    if (name) {
      where.name = ILike(`%${name}%`);
    }

    if (description) {
      where.description = ILike(`%${description}%`);
    }

    if (status) {
      where.status = status;
    }

    const [results, total] = await this.storeMenusRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      relations: {
        createdBy: true,
        updatedBy: true,
      },
    });

    const data = results.map(StoreMenuMapper.toStoreMenuDto);

    return { data, total, page, limit };
  }
}
