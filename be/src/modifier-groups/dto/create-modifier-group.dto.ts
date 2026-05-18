import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNumber,
  IsString,
  MaxLength,
  Min,
  ArrayNotEmpty,
  ValidateNested,
  IsOptional,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for creating a new modifier option within a modifier group.
 */
export class CreateModifierOptionDto {
  @ApiProperty({ type: () => String, example: 'Extra Cheese' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiProperty({ type: () => Number, example: 1.5, description: 'Additional price' })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  priceAddOn: number;

  @ApiPropertyOptional({ type: () => Number, example: 1, description: 'Material ID' })
  @IsOptional()
  @IsNumber()
  materialId?: number;

  @ApiPropertyOptional({ type: () => Number, example: 1, description: 'Recipe item ID' })
  @IsOptional()
  @IsNumber()
  recipeItemId?: number;

  @ApiPropertyOptional({
    type: () => String,
    example: 'base64-image-data',
    description: 'Base64 encoded image',
  })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

/**
 * DTO for creating a new modifier group with its options.
 */
export class CreateModifierGroupDto {
  @ApiProperty({ type: () => String, example: 'Extra Toppings' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiProperty({
    type: () => Number,
    example: 0,
    description: 'Minimum number of selections required',
  })
  @IsNumber()
  @Min(0)
  minSelection: number;

  @ApiProperty({
    type: () => Number,
    example: 3,
    description: 'Maximum number of selections allowed',
  })
  @IsNumber()
  @Min(1)
  maxSelection: number;

  @ApiProperty({
    type: () => [CreateModifierOptionDto],
    description: 'List of modifier options for this group',
    example: [
      { name: 'Extra Cheese', priceAddOn: 1.5 },
      { name: 'Bacon', priceAddOn: 2.0 },
    ],
  })
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => CreateModifierOptionDto)
  modifierOptions: CreateModifierOptionDto[];
}
