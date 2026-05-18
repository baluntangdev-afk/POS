import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type, Transform } from 'class-transformer';
import { IsOptional, IsString, IsInt, Min, Max, IsDate } from 'class-validator';
import { DEFAULT_LIMIT, DEFAULT_PAGE, MAX_LIMIT } from '../../utils/pagination/constants';
import { SalesOrderType, SalesOrderStatus } from '../sales-orders.enum';
import dayjs from 'dayjs';

export class SalesOrderQueryDto {
  @ApiPropertyOptional({
    description: 'Page number (1-based)',
    default: DEFAULT_PAGE,
    minimum: 1,
    example: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = DEFAULT_PAGE;

  @ApiPropertyOptional({
    description: 'Number of records per page',
    default: DEFAULT_LIMIT,
    minimum: 1,
    maximum: MAX_LIMIT,
    example: 10,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_LIMIT)
  limit: number = DEFAULT_LIMIT;

  @ApiPropertyOptional({
    description: 'Record sorting (e.g. "soNumber:ASC" or "soDate:DESC")',
    example: 'soDate:DESC',
  })
  @IsOptional()
  @IsString()
  sort?: string;

  @ApiPropertyOptional({
    description: 'Sales order number',
    example: 'SO-001-2026-0001',
  })
  @IsOptional()
  @IsString()
  soNumber?: string;

  @ApiPropertyOptional({
    description: 'Sales order date (ISO 8601)',
    example: '2026-02-20',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  @Transform(({ value }) => (value ? dayjs(value).startOf('day').toDate() : undefined))
  soDate?: Date;

  @ApiPropertyOptional({
    description: 'Sales order type',
    enum: SalesOrderType,
    example: SalesOrderType.DINE_IN,
  })
  @IsOptional()
  @IsString()
  soType?: SalesOrderType;

  @ApiPropertyOptional({
    description: 'Created by',
    example: 1,
  })
  @IsOptional()
  @Type(() => Number)
  createdBy?: number;

  @ApiPropertyOptional({
    description: 'Sales order status',
    enum: SalesOrderStatus,
    example: SalesOrderStatus.PENDING,
  })
  @IsOptional()
  @IsString()
  status?: SalesOrderStatus;
}
