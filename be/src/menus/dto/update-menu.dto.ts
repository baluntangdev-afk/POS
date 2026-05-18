import { ApiProperty, PartialType } from '@nestjs/swagger';
import { CreateMenuDto } from './create-menu.dto';
import { IsObject, IsOptional } from 'class-validator';
import { User } from '../../users/entities/user.entity';

/**
 * DTO for updating a menu (all fields optional).
 */
export class UpdateMenuDto extends PartialType(CreateMenuDto) {
  @ApiProperty({ description: 'Updated by', example: 1 })
  @IsObject()
  @IsOptional()
  updatedBy?: User;
}
