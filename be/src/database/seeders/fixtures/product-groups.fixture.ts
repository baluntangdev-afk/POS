import * as fs from 'fs';
import * as path from 'path';
import { getAssetsPath } from '../../../utils/path.helper';

export interface ProductGroupFixtureItem {
  name: string;
  description: string;
  imageFileName?: string;
  imageBase64: string;
}

const TINY_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

export const PRODUCT_GROUPS_FIXTURE: ProductGroupFixtureItem[] = [
  {
    name: 'Food',
    description: 'Main food dishes and meals',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Coffee, Drinks & Ice Cream',
    description: 'Hot and cold beverages and gelato',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Baking & Pastry',
    description: 'Baked goods and pastry items',
    imageBase64: TINY_PNG_BASE64,
  },
];

const PRODUCT_GROUPS_ASSETS_SUBDIR = 'product-groups';

export function getProductGroupImageBuffer(item: ProductGroupFixtureItem): Buffer {
  if (item.imageFileName) {
    const filePath = path.join(getAssetsPath(), PRODUCT_GROUPS_ASSETS_SUBDIR, item.imageFileName);
    if (fs.existsSync(filePath)) {
      return fs.readFileSync(filePath);
    }
  }
  return Buffer.from(item.imageBase64, 'base64');
}
