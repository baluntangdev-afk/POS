import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { PaymentMethod } from '../payments.enum';

/**
 * DTO for creating a new payment.
 */
export class CreatePaymentDto {
  @ApiProperty({ description: 'The specific amount for this transaction', example: 100.5 })
  @IsNotEmpty()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  amountPaid: number;

  @ApiProperty({ enum: PaymentMethod, description: 'Payment method' })
  @IsNotEmpty()
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({ description: 'Payment date', default: 'now()' })
  @IsOptional()
  @Type(() => Date)
  paymentDate?: Date;

  @ApiPropertyOptional({
    description: 'ID from the terminal or app',
    example: 'TXN-001',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  transactionReference?: string | null;
}
