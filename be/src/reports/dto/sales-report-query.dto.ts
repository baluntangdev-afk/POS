import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsDate, IsIn, IsOptional, Validate } from 'class-validator';
import dayjs from 'dayjs';
import { DateRangeConstraint } from './validators/date-range.validator';
import { SORT_VALUES, type ProductGroupSalesSort } from '../reports.constants';

/**
 * Query parameters for sales reports (product group, product, user). Date range and optional sort for totalSales.
 */
export class SalesReportQueryDto {
  @ApiProperty({
    description: 'Start date (ISO 8601) of the period. Defaults to start of today.',
    example: '2025-02-16',
  })
  @IsDate()
  @Type(() => Date)
  @Transform(({ value }) =>
    value ? dayjs(value).startOf('day').toDate() : dayjs().startOf('day').toDate(),
  )
  startDate: Date;

  @ApiProperty({
    description: 'End date (ISO 8601) of the period. Defaults to end of today.',
    example: '2025-02-16',
  })
  @IsDate()
  @Type(() => Date)
  @Transform(({ value }) =>
    value ? dayjs(value).endOf('day').toDate() : dayjs().endOf('day').toDate(),
  )
  @Validate(DateRangeConstraint)
  endDate: Date;

  @ApiPropertyOptional({
    description: 'Sort order for totalSales. Default: DESC',
    enum: SORT_VALUES,
    default: 'DESC',
  })
  @IsOptional()
  @IsIn(SORT_VALUES)
  @Transform(({ value }) => value ?? 'DESC')
  sort?: ProductGroupSalesSort = 'DESC';
}
