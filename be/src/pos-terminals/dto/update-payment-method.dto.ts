import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';

export class UpdatePaymentMethodDto {
  @ApiPropertyOptional({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ example: '09171234567', nullable: true })
  @IsString()
  @IsOptional()
  paymentNumber?: string | null;
}
