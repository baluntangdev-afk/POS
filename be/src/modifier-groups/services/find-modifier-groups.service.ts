import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ModifierGroup } from '../entities/modifier-group.entity';
import { ModifierGroupDto } from '../dto/modifier-group.dto';
import { ModifierGroupQueryDto } from '../dto/modifier-group-query.dto';
import { ModifierGroupMapper } from '../mapper/modifier-group.mapper';
import { PaginatedResult } from '../../utils/pagination';

@Injectable()
export class FindModifierGroupsService {
  constructor(
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupRepository: Repository<ModifierGroup>,
  ) {}

  async execute(query: ModifierGroupQueryDto): Promise<PaginatedResult<ModifierGroupDto>> {
    const { page = 1, limit = 10, search } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.modifierGroupRepository
      .createQueryBuilder('modifierGroup')
      .leftJoinAndSelect('modifierGroup.modifierOptions', 'modifierOptions')
      .leftJoinAndSelect('modifierGroup.createdBy', 'createdBy')
      .leftJoinAndSelect('modifierGroup.updatedBy', 'updatedBy')
      .leftJoinAndSelect('modifierGroup.deletedBy', 'deletedBy')
      .where('modifierGroup.deletedAt IS NULL');

    if (search) {
      queryBuilder.andWhere('modifierGroup.name ILIKE :search', { search: `%${search}%` });
    }

    const [modifierGroups, total] = await queryBuilder
      .orderBy('modifierGroup.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    const dtos = modifierGroups.map((group) =>
      ModifierGroupMapper.toModifierGroupDto(group, group.modifierOptions),
    );

    return {
      data: dtos,
      total,
      page,
      limit,
    };
  }
}
