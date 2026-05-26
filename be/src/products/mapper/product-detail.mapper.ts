import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';
import { ModifierGroupDto } from '../dto/product-details/modifier-group.dto';
import { ModifierOptionDto } from '../dto/product-details/modifier-options.dto';
import { ProductDetailsDto } from '../dto/product-details/product-details.dto';
import { Product } from '../entities/product.entity';

export class ProductDetailMapper {
  static toDto(product: Product, args?: { currencySign?: string }): ProductDetailsDto {
    const dto = new ProductDetailsDto();

    dto.id = product.id;
    dto.name = product.name;
    dto.description = product.description;
    dto.imageUrl = product.imageUrl ? Buffer.from(product.imageUrl).toString('base64') : null;
    dto.currencySign = args?.currencySign ?? '₱';
    dto.displayPrice = product.price ?? '0';
    dto.defaultVariantId = product.productVariants?.[0]?.id ?? null;
    dto.modifierGroups = [];

    const modifiers = product.productGroup?.modifiers;
    if (modifiers && modifiers.length > 0) {
      for (const mg of modifiers) {
        dto.modifierGroups.push(this.toModifierGroupDto(mg));
      }
    }

    return dto;
  }

  static toModifierGroupDto(modifierGroup: ModifierGroup): ModifierGroupDto {
    const modifierGroupDto = new ModifierGroupDto();

    modifierGroupDto.menuItemModifierId = 0;
    modifierGroupDto.id = modifierGroup.id;
    modifierGroupDto.name = modifierGroup.name;
    modifierGroupDto.minSelection = modifierGroup.minSelection ?? 0;
    modifierGroupDto.maxSelection = modifierGroup.maxSelection ?? 1;
    modifierGroupDto.options = [];

    if (modifierGroup.modifierOptions && modifierGroup.modifierOptions.length > 0) {
      for (const mo of modifierGroup.modifierOptions) {
        modifierGroupDto.options.push(this.toModifierOptionDto(mo));
      }
    }

    return modifierGroupDto;
  }

  static toModifierOptionDto(modifierOption: ModifierOption): ModifierOptionDto {
    const modifierOptionDto = new ModifierOptionDto();

    modifierOptionDto.id = modifierOption.id;
    modifierOptionDto.name = modifierOption.name;
    modifierOptionDto.priceAddOn = modifierOption.priceAddOn;
    modifierOptionDto.materialId = modifierOption.materialId;
    modifierOptionDto.recipeItemId = modifierOption.recipeItemId;
    modifierOptionDto.imageUrl = modifierOption.imageUrl
      ? Buffer.from(modifierOption.imageUrl).toString('base64')
      : null;

    return modifierOptionDto;
  }
}
