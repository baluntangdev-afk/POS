import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsDate, IsObject, IsOptional, IsString } from 'class-validator';
import { User } from '../entities/user.entity';
import { PartialType } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';

export class UpdateUserDto extends PartialType(CreateUserDto) {
  @ApiProperty({ description: 'Device PIN', example: '123456' })
  @IsString()
  @IsOptional()
  devicePin?: string;

  @ApiProperty({ description: 'PIN changed', example: false })
  @IsBoolean()
  @IsOptional()
  isPinChanged?: boolean;

  @ApiProperty({ description: 'Last login', example: new Date() })
  @IsDate()
  @IsOptional()
  lastLogin?: Date;

  @ApiProperty({ description: 'Updated by', example: 1 })
  @IsObject()
  @IsOptional()
  updatedBy?: User;
}
