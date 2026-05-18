import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsEnum } from 'class-validator';
import { PaginatedQueryDto } from '../../utils/pagination';
import { StoreMenuStatus } from '../store-menus.enum';

export class StoreMenuQueryDto extends PaginatedQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by name',
    example: 'Breakfast',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    description: 'Filter by description',
    example: 'Available breakfast items',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: StoreMenuStatus,
    example: StoreMenuStatus.ACTIVE,
  })
  @IsOptional()
  @IsEnum(StoreMenuStatus)
  status?: StoreMenuStatus;
}
