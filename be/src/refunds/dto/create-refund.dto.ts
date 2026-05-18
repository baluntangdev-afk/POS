import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
  IsArray,
  IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';
import { PaymentMethod } from '../../payments/payments.enum';
import { CreateRefundItemDto } from './create-refund-item.dto';
import { User } from '../../users/entities/user.entity';

/**
 * DTO for creating a new refund.
 */
export class CreateRefundDto {
  @ApiProperty({
    description: 'Original sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @IsNotEmpty()
  @IsUUID(7)
  originalSalesOrderId: string;

  @ApiProperty({ description: 'Explanation for the refund' })
  @IsNotEmpty()
  @IsString()
  reason: string;

  @ApiProperty({ description: 'Exact amount returned', example: 100.5 })
  @IsNotEmpty()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  totalRefundAmount: number;

  @ApiProperty({ enum: PaymentMethod, description: 'Payment method' })
  @IsNotEmpty()
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({
    description: 'Reference ID from the provider',
    example: 'REF-123456789',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  transactionReference?: string | null;

  @ApiProperty({
    description: 'List of refund items',
    type: [CreateRefundItemDto],
  })
  @IsNotEmpty()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRefundItemDto)
  refundItems: CreateRefundItemDto[];

  // Hidden from dto
  id?: string;
  refundNumber: string;
  refundDate: Date;
  createdBy: User;
  updatedBy: User;
}
