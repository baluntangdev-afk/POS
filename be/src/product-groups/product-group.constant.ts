import type { FindOptionsSelect } from 'typeorm';
import { Product } from '../products/entities/product.entity';

export const PRODUCT_LIST_SELECT: FindOptionsSelect<Product> = {
  id: true,
  name: true,
  imageUrl: true,
};
