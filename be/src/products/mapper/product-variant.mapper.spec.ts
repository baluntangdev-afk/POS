import { ProductVariantMapper } from './product-variant.mapper';
import { ProductVariantStatus } from '../products.enum';
import { ProductVariant } from '../entities/product-variant.entity';

describe('ProductVariantMapper.toProductVariantDto', () => {
  it('should map status: Active to isActive: true', () => {
    const entity = {
      id: 1,
      product: { id: 5 },
      name: 'Regular',
      price: 100,
      isDefault: true,
      status: ProductVariantStatus.ACTIVE,
    } as unknown as ProductVariant;

    expect(ProductVariantMapper.toProductVariantDto(entity).isActive).toBe(true);
  });

  it('should map status: Disabled to isActive: false', () => {
    const entity = {
      id: 1,
      product: { id: 5 },
      name: 'Regular',
      price: 100,
      isDefault: true,
      status: ProductVariantStatus.DISABLED,
    } as unknown as ProductVariant;

    expect(ProductVariantMapper.toProductVariantDto(entity).isActive).toBe(false);
  });
});
