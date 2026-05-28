import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';

export class CreatePosTerminalDto {
  @ApiProperty({ example: 'ABC Corporation' })
  @IsString()
  @IsNotEmpty()
  legalName: string;

  @ApiProperty({ example: '123 Main St., City' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ example: '123-456-789-000' })
  @IsString()
  @IsNotEmpty()
  tinNumber: string;

  @ApiProperty({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({ example: '09171234567' })
  @IsString()
  @IsOptional()
  paymentNumber?: string;
}
