import { IsEnum, IsNotEmpty, IsOptional, IsString, ValidateIf } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';

export class UpdatePaymentMethodDto {
  @ApiPropertyOptional({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ example: 'PayMaya', nullable: true, description: 'Required when paymentMethod is Other' })
  @ValidateIf((o: UpdatePaymentMethodDto) => o.paymentMethod === PaymentMethod.OTHER)
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  paymentMethodName?: string | null;

  @ApiPropertyOptional({ example: '09171234567', nullable: true })
  @IsString()
  @IsOptional()
  paymentNumber?: string | null;
}
