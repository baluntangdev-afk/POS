import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantDto } from '../dto/product-variant.dto';
import { ProductVariantStatus } from '../products.enum';

export class ProductVariantMapper {
  static toProductVariantDto(entity: ProductVariant): ProductVariantDto {
    return {
      id: entity.id,
      productId: entity.product.id,
      name: entity.name,
      price: Number(entity.price),
      isDefault: entity.isDefault,
      isActive: entity.status === ProductVariantStatus.ACTIVE,
    };
  }
}
