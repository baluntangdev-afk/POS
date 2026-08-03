import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Discount applied to a sales order item (e.g. Senior Citizen / PWD).
 */
export class ApplyDiscountItemDiscountDto {
  @ApiProperty({ description: 'Discount ID', example: 1 })
  @IsNumber()
  @Type(() => Number)
  id: number;

  @ApiProperty({ description: 'Discount name', example: 'Senior Citizen / PWD' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Discount value (e.g. percentage)', example: 20 })
  @IsNumber()
  @Type(() => Number)
  value: number;

  @ApiPropertyOptional({
    description: 'Beneficiary ID number (Senior Citizen/PWD discounts only)',
    example: 'SC-2024-00001',
  })
  @IsOptional()
  @IsString()
  idNumber?: string;

  @ApiPropertyOptional({
    description: "Beneficiary's name (Senior Citizen/PWD discounts only)",
    example: 'Juan Dela Cruz',
  })
  @IsOptional()
  @IsString()
  beneficiaryName?: string;
}
