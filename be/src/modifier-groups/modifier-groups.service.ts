import { Injectable } from '@nestjs/common';
import { CreateModifierGroupDto } from './dto/create-modifier-group.dto';
import { UpdateModifierGroupDto } from './dto/update-modifier-group.dto';
import { ModifierGroupDto } from './dto/modifier-group.dto';
import { ModifierGroupQueryDto } from './dto/modifier-group-query.dto';
import { User } from '../users/entities/user.entity';
import { PaginatedResult } from '../utils/pagination';
import { ModifierOption } from './entities/modifier-option.entity';
import { CreateModifierGroupService } from './services/create-modifier-group.service';
import { FindModifierGroupsService } from './services/find-modifier-groups.service';
import { FindModifierGroupService } from './services/find-modifier-group.service';
import { UpdateModifierGroupService } from './services/update-modifier-group.service';
import { DeleteModifierGroupService } from './services/delete-modifier-group.service';
import { FindModifierOptionWithRelationService } from './services/find-modifier-option-with-relation.service';

@Injectable()
export class ModifierGroupsService {
  constructor(
    private readonly createModifierGroupService: CreateModifierGroupService,
    private readonly findModifierGroupsService: FindModifierGroupsService,
    private readonly findModifierGroupService: FindModifierGroupService,
    private readonly updateModifierGroupService: UpdateModifierGroupService,
    private readonly deleteModifierGroupService: DeleteModifierGroupService,
    private readonly findModifierOptionWithRelationService: FindModifierOptionWithRelationService,
  ) {}

  async create(
    createModifierGroupDto: CreateModifierGroupDto,
    causer: User,
  ): Promise<ModifierGroupDto> {
    return this.createModifierGroupService.execute(createModifierGroupDto, causer);
  }

  async findAll(query: ModifierGroupQueryDto): Promise<PaginatedResult<ModifierGroupDto>> {
    return this.findModifierGroupsService.execute(query);
  }

  async findOne(id: number): Promise<ModifierGroupDto> {
    return this.findModifierGroupService.execute(id);
  }

  async update(
    id: number,
    updateModifierGroupDto: UpdateModifierGroupDto,
    causer: User,
  ): Promise<ModifierGroupDto> {
    await this.updateModifierGroupService.execute(id, updateModifierGroupDto, causer);
    return this.findModifierGroupService.execute(id);
  }

  async remove(id: number, causer: User): Promise<{ message: string }> {
    await this.findModifierGroupService.execute(id);
    await this.deleteModifierGroupService.execute(id, causer);
    return { message: 'Modifier group deleted successfully' };
  }

  async findModifierOptionWithRelationById(ids: number[]): Promise<Map<number, ModifierOption>> {
    return this.findModifierOptionWithRelationService.execute(ids);
  }
}
