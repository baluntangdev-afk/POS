import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { RecipeStatus } from '../recipes.enum';

/**
 * DTO for creating a new recipe.
 */
export class CreateRecipeDto {
  @ApiProperty({ description: 'Product variant ID', example: 1 })
  @IsNotEmpty()
  @IsInt()
  @Type(() => Number)
  productVariantId: number;

  @ApiProperty({ type: () => String, example: 'Standard Beef Patty Mix' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(150)
  name: string;

  @ApiPropertyOptional({ description: 'Prep time in minutes (KDS)', example: 15 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  prepTimeMinutes?: number | null;

  @ApiPropertyOptional({ description: 'Yield quantity', example: 1, default: 1 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  yieldQty?: number;

  @ApiProperty({ description: 'Yield unit of measure ID', example: 1 })
  @IsNotEmpty()
  @IsInt()
  @Type(() => Number)
  yieldUnitId: number;

  @ApiPropertyOptional({ enum: RecipeStatus, default: RecipeStatus.DRAFT })
  @IsOptional()
  @IsEnum(RecipeStatus)
  status?: RecipeStatus;
}
