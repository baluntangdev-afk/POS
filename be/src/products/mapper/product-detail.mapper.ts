import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';
import { ModifierGroupDto } from '../dto/product-details/modifier-group.dto';
import { ModifierOptionDto } from '../dto/product-details/modifier-options.dto';
import { ProductDetailsDto } from '../dto/product-details/product-details.dto';
import { ProductVariantDto } from '../dto/product-details/variant.dto';
import { ProductVariant } from '../entities/product-variant.entity';
import { Product } from '../entities/product.entity';

export class ProductDetailMapper {
  static toDto(product: Product, args?: { currencySign?: string }): ProductDetailsDto {
    const dto = new ProductDetailsDto();

    dto.id = product.id;
    dto.name = product.name;
    dto.description = product.description;
    dto.imageUrl = product.imageUrl ? Buffer.from(product.imageUrl).toString('base64') : null;

    if (product.productVariants && product.productVariants.length > 0) {
      dto.variants = [];
      for (const pv of product.productVariants) {
        dto.variants.push(this.toVariantDto(pv));
      }

      // for displaying price
      dto.displayPrice = dto.variants.find((v) => v.isDefault)?.displayPrice ?? '0';
    }

    if (args?.currencySign) {
      dto.currencySign = args.currencySign;
    }

    return dto;
  }

  static toVariantDto(productVariant: ProductVariant): ProductVariantDto {
    const variantDto = new ProductVariantDto();

    variantDto.id = productVariant.id;
    variantDto.name = productVariant.name;
    variantDto.isDefault = productVariant.isDefault;

    if (productVariant.menuItems && productVariant.menuItems.length > 0) {
      const menuItem = productVariant.menuItems[0];
      variantDto.menuItemId = menuItem.id;
      variantDto.displayPrice = menuItem.displayPrice;

      if (menuItem.menuItemModifiers && menuItem.menuItemModifiers.length > 0) {
        variantDto.modifierGroups = [];
        for (const mm of menuItem.menuItemModifiers) {
          variantDto.modifierGroups.push(this.toModifierGroupDto(mm.id, mm.modifierGroup));
        }
      }
    }

    return variantDto;
  }

  static toModifierGroupDto(
    menuItemModifierId: number,
    modifierGroup: ModifierGroup,
  ): ModifierGroupDto {
    const modifierGroupDto = new ModifierGroupDto();

    modifierGroupDto.menuItemModifierId = menuItemModifierId;
    modifierGroupDto.id = modifierGroup.id;
    modifierGroupDto.name = modifierGroup.name;
    modifierGroupDto.minSelection = modifierGroup.minSelection ?? 0;
    modifierGroupDto.maxSelection = modifierGroup.maxSelection ?? 1;

    if (modifierGroup.modifierOptions && modifierGroup.modifierOptions.length > 0) {
      modifierGroupDto.options = [];
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
