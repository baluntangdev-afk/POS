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
    name: 'Coffee',
    description: 'Hot, iced and blended coffee beverages',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Non-Coffee',
    description: 'Hot and iced non-coffee beverages',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Gelato',
    description: 'Soft serve ice cream selections',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Fruit Shake',
    description: 'Premium fruit shakes',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Fruit Boost',
    description: 'Fruit teas and lemonades',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Meals',
    description: 'Breakfast and set meals',
    imageBase64: TINY_PNG_BASE64,
  },
];

const PRODUCT_GROUPS_ASSETS_SUBDIR = 'product-groups';

export function getProductGroupImageBuffer(
  item: ProductGroupFixtureItem,
): Buffer {
  if (item.imageFileName) {
    const filePath = path.join(
      getAssetsPath(),
      PRODUCT_GROUPS_ASSETS_SUBDIR,
      item.imageFileName,
    );

    if (fs.existsSync(filePath)) {
      return fs.readFileSync(filePath);
    }
  }

  return Buffer.from(item.imageBase64, 'base64');
}