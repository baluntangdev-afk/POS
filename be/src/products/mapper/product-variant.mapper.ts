import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantDto } from '../dto/product-variant.dto';

export class ProductVariantMapper {
  static toProductVariantDto(entity: ProductVariant): ProductVariantDto {
    return {
      id: entity.id,
      productId: entity.product.id,
      name: entity.name,
      isDefault: entity.isDefault,
    };
  }
}
