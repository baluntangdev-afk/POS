import { IsArray, IsDate, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for creating an inventory count (no controller; used internally).
 */
export class CreateInventoryCountDto {
  @IsString()
  salesOrderId: string;

  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  typeId: number;

  @IsNotEmpty()
  @IsDate()
  @Type(() => Date)
  countDate: Date;

  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  createdById: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  updatedById: number | null;
}
