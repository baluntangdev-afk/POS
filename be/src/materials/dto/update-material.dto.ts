import { ApiProperty, PartialType } from '@nestjs/swagger';
import { CreateMaterialDto } from './create-material.dto';
import { IsObject, IsOptional } from 'class-validator';
import { User } from '../../users/entities/user.entity';

/**
 * DTO for updating a material (all fields optional).
 */
export class UpdateMaterialDto extends PartialType(CreateMaterialDto) {
  @ApiProperty({ description: 'Updated by', example: 1 })
  @IsObject()
  @IsOptional()
  updatedBy?: User;
}
