import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * One line of an inventory count (variant or material, system/counted/variance qty, unit).
 */
export class CreateInventoryCountItemDto {
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  productVariantId: number | null;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  materialId: number | null;

  @IsNotEmpty()
  @IsString()
  systemQty: string;

  @IsNotEmpty()
  @IsString()
  countedQty: string;

  @IsNotEmpty()
  @IsString()
  varianceQty: string;

  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  unitId: number;
}
