import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsOptional, IsDate, Validate } from 'class-validator';
import dayjs from 'dayjs';
import { DateRangeConstraint } from './validators/date-range.validator';

/**
 * Query parameters for sales report.
 */
export class SalesQueryDto {
  @ApiPropertyOptional({
    description: 'Date (ISO 8601) for the start date of the report. Defaults to today.',
    example: '2025-02-12',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  @Transform(({ value }) => (value ? dayjs(value).toDate() : dayjs().startOf('day').toDate()))
  startDate?: Date;

  @ApiPropertyOptional({
    description: 'Date (ISO 8601) for the end date of the report. Defaults to today.',
    example: '2025-02-12',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  @Transform(({ value }) => (value ? dayjs(value).toDate() : dayjs().endOf('day').toDate()))
  @Validate(DateRangeConstraint)
  endDate?: Date;
}
