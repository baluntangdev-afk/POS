import { Module } from '@nestjs/common';
import { ModifierGroupsService } from './modifier-groups.service';
import { ModifierGroupsController } from './modifier-groups.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ModifierGroup } from './entities/modifier-group.entity';
import { ModifierOption } from './entities/modifier-option.entity';
import { CreateModifierGroupService } from './services/create-modifier-group.service';
import { FindModifierGroupsService } from './services/find-modifier-groups.service';
import { FindModifierGroupService } from './services/find-modifier-group.service';
import { UpdateModifierGroupService } from './services/update-modifier-group.service';
import { DeleteModifierGroupService } from './services/delete-modifier-group.service';
import { FindModifierOptionWithRelationService } from './services/find-modifier-option-with-relation.service';

@Module({
  imports: [TypeOrmModule.forFeature([ModifierGroup, ModifierOption])],
  controllers: [ModifierGroupsController],
  providers: [
    ModifierGroupsService,
    CreateModifierGroupService,
    FindModifierGroupsService,
    FindModifierGroupService,
    UpdateModifierGroupService,
    DeleteModifierGroupService,
    FindModifierOptionWithRelationService,
  ],
  exports: [ModifierGroupsService],
})
export class ModifierGroupsModule {}
