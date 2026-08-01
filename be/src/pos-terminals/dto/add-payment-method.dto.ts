import { IsEnum, IsNotEmpty, IsOptional, IsString, ValidateIf } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';

export class AddPaymentMethodDto {
  @ApiProperty({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({ example: 'PayMaya', description: 'Required when paymentMethod is Other' })
  @ValidateIf((o: AddPaymentMethodDto) => o.paymentMethod === PaymentMethod.OTHER)
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  paymentMethodName?: string;

  @ApiPropertyOptional({ example: '09171234567' })
  @IsString()
  @IsOptional()
  paymentNumber?: string;
}
