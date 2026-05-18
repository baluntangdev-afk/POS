import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ModifierGroup } from '../entities/modifier-group.entity';
import { ModifierGroupDto } from '../dto/modifier-group.dto';
import { ModifierGroupMapper } from '../mapper/modifier-group.mapper';

@Injectable()
export class FindModifierGroupService {
  constructor(
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupRepository: Repository<ModifierGroup>,
  ) {}

  async execute(id: number): Promise<ModifierGroupDto> {
    const modifierGroup = await this.modifierGroupRepository
      .createQueryBuilder('modifierGroup')
      .leftJoinAndSelect('modifierGroup.modifierOptions', 'modifierOptions')
      .leftJoinAndSelect('modifierGroup.createdBy', 'createdBy')
      .leftJoinAndSelect('modifierGroup.updatedBy', 'updatedBy')
      .leftJoinAndSelect('modifierGroup.deletedBy', 'deletedBy')
      .where('modifierGroup.id = :id', { id })
      .andWhere('modifierGroup.deletedAt IS NULL')
      .getOne();

    if (!modifierGroup) {
      throw new NotFoundException(`Modifier group with ID ${id} not found`);
    }

    return ModifierGroupMapper.toModifierGroupDto(modifierGroup, modifierGroup.modifierOptions);
  }
}
