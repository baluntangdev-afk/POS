import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateModifierGroupDto } from '../dto/update-modifier-group.dto';
import { User } from '../../users/entities/user.entity';
import { ModifierGroup } from '../entities/modifier-group.entity';
import { ModifierOption } from '../entities/modifier-option.entity';
import { EntityHelper } from '../../utils/entity.helper';

@Injectable()
export class UpdateModifierGroupService {
  constructor(
    @InjectRepository(ModifierGroup)
    private readonly modifierGroupRepository: Repository<ModifierGroup>,
    @InjectRepository(ModifierOption)
    private readonly modifierOptionRepository: Repository<ModifierOption>,
  ) {}

  async execute(
    id: number,
    updateModifierGroupDto: UpdateModifierGroupDto,
    causer: User,
  ): Promise<void> {
    const modifierGroup = await this.modifierGroupRepository.findOne({
      where: { id },
      relations: ['modifierOptions'],
    });

    if (!modifierGroup) {
      throw new NotFoundException(`Modifier group with ID ${id} not found`);
    }

    const { modifierOptions, ...modifierGroupData } = updateModifierGroupDto;

    const payload: Partial<ModifierGroup> = {
      ...modifierGroupData,
      updatedBy: causer,
    };

    await this.modifierGroupRepository.update(id, EntityHelper.toPartialEntity(payload));

    if (modifierOptions) {
      const deletePayload: Partial<ModifierOption> = { deletedBy: causer };
      await this.modifierOptionRepository.update(
        { modifierGroup: { id: modifierGroup.id } },
        EntityHelper.toPartialEntity(deletePayload),
      );
      await this.modifierOptionRepository.softDelete({
        modifierGroup: { id: modifierGroup.id },
      });

      await Promise.all(
        modifierOptions.map((optionData) =>
          this.modifierOptionRepository.save({
            ...optionData,
            modifierGroup: { id: modifierGroup.id },
            createdBy: causer,
            updatedBy: causer,
            priceAddOn: optionData.priceAddOn?.toString(),
            imageUrl: optionData.imageUrl ? Buffer.from(optionData.imageUrl, 'base64') : null,
          }),
        ),
      );
    }
  }
}
