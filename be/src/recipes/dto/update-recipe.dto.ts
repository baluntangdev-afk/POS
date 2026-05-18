import { ApiProperty, PartialType } from '@nestjs/swagger';
import { CreateRecipeDto } from './create-recipe.dto';
import { IsObject, IsOptional } from 'class-validator';
import { User } from '../../users/entities/user.entity';

/**
 * DTO for updating a recipe (all fields optional).
 */
export class UpdateRecipeDto extends PartialType(CreateRecipeDto) {
  @ApiProperty({ description: 'Updated by', example: 1 })
  @IsObject()
  @IsOptional()
  updatedBy?: User;
}
