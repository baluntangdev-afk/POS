import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ModifierGroup } from '../entities/modifier-group.entity';
import { User } from '../../users/entities/user.entity';
import { EntityHelper } from '../../utils/entity.helper';

@Injectable()
export class DeleteModifierGroupService {
  constructor(
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupRepository: Repository<ModifierGroup>,
  ) {}

  async execute(id: number, causer: User): Promise<void> {
    const payload: Partial<ModifierGroup> = { deletedBy: causer };
    await this.modifierGroupRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.modifierGroupRepository.softDelete(id);
  }
}
