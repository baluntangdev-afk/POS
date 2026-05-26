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
    name: 'Burgers',
    description: 'All our signature beef and chicken burgers',
    imageFileName: 'burgers.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Chicken',
    description: 'Crispy and grilled chicken dishes',
    imageFileName: 'chicken.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Rice Meals',
    description: 'Hearty rice bowls and Filipino favourites',
    imageFileName: 'rice-meals.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Sides',
    description: 'Perfect add-ons to complete your meal',
    imageFileName: 'sides.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Beverages',
    description: 'Cold drinks and refreshing beverages',
    imageFileName: 'beverages.png',
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
