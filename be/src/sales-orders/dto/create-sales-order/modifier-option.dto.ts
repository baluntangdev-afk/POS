import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
import { RecipeItem } from '../../../recipes/entities/recipe-item.entity';
import { CreateSalesOrderItemDto } from './sales-order-item.dto';
import { ProductVariant } from '../../../products/entities/product-variant.entity';
import { Recipe } from '../../../recipes/entities/recipe.entity';
import { Material } from '../../../materials/entities/material.entity';

/**
 * Modifier option for create sales order line. Only id and price needed.
 */
export class CreateSalesOrderModifierOptionDto {
  @ApiProperty({ description: 'Modifier option ID', example: 1 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  id: number;

  @ApiProperty({ description: 'Price add-on', example: 80 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  priceAddOn: number;

  // Hidden from dto
  name: string;
  material: Material;
  createSoItem: CreateSalesOrderItemDto;
  productVariant: ProductVariant;
  recipe: Recipe;
  itemSequence: number;
  quantity: number;
  recipeItemId: number;
  recipeItem: RecipeItem;
}
