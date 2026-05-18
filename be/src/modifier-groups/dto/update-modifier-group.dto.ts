import { PartialType } from '@nestjs/swagger';
import { CreateModifierOptionDto } from './create-modifier-group.dto';
import { CreateModifierGroupDto } from './create-modifier-group.dto';

/**
 * DTO for updating a modifier option.
 */
export class UpdateModifierOptionDto extends PartialType(CreateModifierOptionDto) {}

/**
 * DTO for updating a modifier group with its options.
 */
export class UpdateModifierGroupDto extends PartialType(CreateModifierGroupDto) {}
