import { ApiProperty } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsDate, Validate } from 'class-validator';
import dayjs from 'dayjs';
import { DateRangeConstraint } from './validators/date-range.validator';

/**
 * Query parameters for hourly sales report.
 */
export class HourlySalesQueryDto {
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
}
