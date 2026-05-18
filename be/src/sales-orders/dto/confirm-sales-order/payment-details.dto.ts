import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { PaymentMethod } from '../../../payments/payments.enum';

/**
 * Payment details for confirming a sales order.
 */
export class PaymentDetailsDto {
  @ApiProperty({ description: 'Payee name', example: 'Amanda' })
  @IsString()
  payeeName: string;

  @ApiProperty({ description: 'Payment method', enum: PaymentMethod, example: 'Cash' })
  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  @ApiProperty({ description: 'Gross amount', example: '330.00' })
  @IsString()
  grossAmount: string;

  @ApiProperty({ description: 'Tax amount', example: '39.60' })
  @IsString()
  taxAmount: string;

  @ApiProperty({ description: 'Net amount', example: '369.60' })
  @IsString()
  netAmount: string;

  @ApiProperty({ description: 'Amount paid', example: '380.00' })
  @IsString()
  amountPaid: string;

  @ApiProperty({ description: 'Change given', example: '10.40' })
  @IsString()
  change: string;

  @ApiProperty({ description: 'Transaction reference', example: '1234567890' })
  @IsOptional()
  @IsString()
  transactionReference?: string;
}
