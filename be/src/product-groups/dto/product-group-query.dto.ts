import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import { PaginatedQueryDto } from '../../utils/pagination';

export class ProductGroupQueryDto extends PaginatedQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by name',
    example: 'Beverages',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    description: 'Filter by description',
    example: 'Cold drinks',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
