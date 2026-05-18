import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateModifierGroupDto } from '../dto/create-modifier-group.dto';
import { User } from '../../users/entities/user.entity';
import { ModifierGroup } from '../entities/modifier-group.entity';
import { ModifierOption } from '../entities/modifier-option.entity';
import { ModifierGroupDto } from '../dto/modifier-group.dto';
import { ModifierGroupMapper } from '../mapper/modifier-group.mapper';

@Injectable()
export class CreateModifierGroupService {
  constructor(
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupRepository: Repository<ModifierGroup>,
    @InjectRepository(ModifierOption)
    private readonly modifierOptionRepository: Repository<ModifierOption>,
  ) {}

  async execute(
    createModifierGroupDto: CreateModifierGroupDto,
    causer: User,
  ): Promise<ModifierGroupDto> {
    const { modifierOptions, ...modifierGroupData } = createModifierGroupDto;

    const payload: Partial<ModifierGroup> = {
      ...modifierGroupData,
      createdBy: causer,
      updatedBy: causer,
    };

    const entity = this.modifierGroupRepository.create(payload);
    const savedModifierGroup = await this.modifierGroupRepository.save(entity);

    const savedModifierOptions = await Promise.all(
      modifierOptions.map((optionData) => {
        const optionPayload: Partial<ModifierOption> = {
          ...optionData,
          modifierGroup: savedModifierGroup,
          createdBy: causer,
          updatedBy: causer,
          priceAddOn: optionData.priceAddOn.toString(),
          imageUrl: optionData.imageUrl ? Buffer.from(optionData.imageUrl, 'base64') : null,
        };
        return this.modifierOptionRepository.save(optionPayload);
      }),
    );

    return ModifierGroupMapper.toModifierGroupDto(savedModifierGroup, savedModifierOptions);
  }
}
