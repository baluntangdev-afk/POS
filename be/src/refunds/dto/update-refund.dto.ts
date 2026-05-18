import { ApiProperty, PartialType } from '@nestjs/swagger';
import { CreateRefundDto } from './create-refund.dto';
import { IsObject, IsOptional } from 'class-validator';
import { User } from '../../users/entities/user.entity';

/**
 * DTO for updating a refund (all fields optional).
 */
export class UpdateRefundDto extends PartialType(CreateRefundDto) {
  @ApiProperty({ description: 'Updated by', example: 1 })
  @IsObject()
  @IsOptional()
  updatedBy?: User;
}
