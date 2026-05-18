import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type, Transform } from 'class-transformer';
import { IsOptional, IsString, IsInt, Min, Max, IsDate, IsEnum, IsUUID } from 'class-validator';
import { DEFAULT_LIMIT, DEFAULT_PAGE, MAX_LIMIT } from '../../utils/pagination/constants';
import { PaymentMethod } from '../../payments/payments.enum';
import dayjs from 'dayjs';

export class RefundQueryDto {
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
    description: 'Record sorting (e.g. "refund_date:DESC" or "refund_number:ASC")',
    example: 'refund_date:DESC',
  })
  @IsOptional()
  @IsString()
  sort?: string;

  @ApiPropertyOptional({
    description: 'Payment method',
    enum: PaymentMethod,
    example: PaymentMethod.CASH,
  })
  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({
    description: 'Refund date (ISO 8601)',
    example: '2026-02-20',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  @Transform(({ value }) => (value ? dayjs(value).startOf('day').toDate() : undefined))
  refundDate?: Date;

  @ApiPropertyOptional({
    description: 'Transaction reference',
    example: 'REF-123456789',
  })
  @IsOptional()
  @IsString()
  transactionReference?: string;

  @ApiPropertyOptional({
    description: 'Original sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @IsOptional()
  @IsUUID(7)
  originalSalesOrderId?: string;

  @ApiPropertyOptional({
    description: 'Refund number',
    example: 'REFUND-001-2026-0001',
  })
  @IsOptional()
  @IsString()
  refundNumber?: string;
}
