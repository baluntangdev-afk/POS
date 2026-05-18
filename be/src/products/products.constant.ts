import type { FindOptionsSelect } from 'typeorm';
import { Product } from './entities/product.entity';
import { ProductVariant } from './entities/product-variant.entity';

export const PRODUCT_LIST_SELECT: FindOptionsSelect<Product> = {
  id: true,
  name: true,
  description: true,
  imageUrl: true,
};

export const PRODUCT_VARIANT_LIST_SELECT: FindOptionsSelect<ProductVariant> = {
  id: true,
  name: true,
  status: true,
  isDefault: true,
};
