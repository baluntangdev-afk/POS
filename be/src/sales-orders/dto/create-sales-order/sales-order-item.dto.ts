import { ApiProperty } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { CreateSalesOrderModifierGroupDto } from './modifier-group.dto';
import { ProductVariant } from '../../../products/entities/product-variant.entity';
import { RecipeItem } from '../../../recipes/entities/recipe-item.entity';
import { User } from '../../../users/entities/user.entity';
import { ApplyDiscountItemDiscountDto } from '../add-discount/apply-discount-item-discount.dto';

/**
 * One sales order line = one product variant. Id, quantity, price, and optional modifier selections.
 */
export class CreateSalesOrderItemDto {
  @ApiProperty({ description: 'Product variant ID', example: 1 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  productVariantId: number;

  @ApiProperty({ description: 'Quantity', example: 1 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  quantity: number;

  @ApiProperty({ description: 'Unit or line price', example: 100 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  price: number;

  @ApiProperty({
    type: () => [CreateSalesOrderModifierGroupDto],
    description: 'Selected modifier groups and options (optional)',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSalesOrderModifierGroupDto)
  modifierGroups: CreateSalesOrderModifierGroupDto[] = [];

  @ApiProperty({
    type: () => ApplyDiscountItemDiscountDto,
    description: 'Discount applied to this item (optional)',
    required: false,
  })
  @IsOptional()
  @IsObject()
  @Type(() => ApplyDiscountItemDiscountDto)
  discount?: ApplyDiscountItemDiscountDto;

  // Hidden from dto
  causer: User;
  productVariant: ProductVariant;
  recipeId: number;
  itemSequence: number;
  description: string;
  addOn: boolean;
  recipeItem: RecipeItem;
}
