import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';

export class UpdatePosTerminalDto {
  @ApiPropertyOptional({ example: 'ABC Corporation' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  legalName?: string;

  @ApiPropertyOptional({ example: '123 Main St., City' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional({ example: '123-456-789-000' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  tinNumber?: string;

  @ApiPropertyOptional({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ example: '09171234567', nullable: true })
  @IsString()
  @IsOptional()
  paymentNumber?: string | null;
}
