import { ApiProperty, PartialType } from '@nestjs/swagger';
import { CreateDiscountDto } from './create-discount.dto';
import { IsObject, IsOptional } from 'class-validator';
import { User } from '../../users/entities/user.entity';

/**
 * DTO for updating a discount (all fields optional).
 */
export class UpdateDiscountDto extends PartialType(CreateDiscountDto) {
  @ApiProperty({ description: 'Updated by', example: 1 })
  @IsObject()
  @IsOptional()
  updatedBy?: User;
}
