import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
import { PaginatedQueryDto } from '../../utils/pagination';

export class ProductQueryDto extends PaginatedQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by name',
    example: 'Sinigang',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    description: 'Filter by description',
    example: 'Filipino soup',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Filter by product group ID',
    example: 1,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  groupId?: number;
}
