import * as fs from 'fs';
import * as path from 'path';
import { getAssetsPath } from '../../../utils/path.helper';

/**
 * Product group seed data with inline base64 images.
 * When assets exist under app root (e.g. POSApp/assets/product-groups/*.png), they are used instead.
 */
export interface ProductGroupFixtureItem {
  name: string;
  description: string;
  /** Filename (no path) for optional file under assets/product-groups/, e.g. "beverages.png" */
  imageFileName?: string;
  /** Base64-encoded image fallback when file is not found. Decoded to bytea in the entity. */
  imageBase64: string;
}

/** 1x1 transparent PNG (~67 bytes) – fallback when asset file is missing */
const TINY_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

export const PRODUCT_GROUPS_FIXTURE: ProductGroupFixtureItem[] = [
  {
    name: 'Beverages',
    description: 'Beverages',
    imageFileName: 'beverages.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Dessert',
    description: 'Dessert',
    imageFileName: 'dessert.png',
    imageBase64: TINY_PNG_BASE64,
  },
  { name: 'Meals', description: 'Meals', imageFileName: 'meals.png', imageBase64: TINY_PNG_BASE64 },
  {
    name: 'Sandwiches',
    description: 'Sandwiches',
    imageFileName: 'sandwiches.png',
    imageBase64: TINY_PNG_BASE64,
  },
];

const PRODUCT_GROUPS_ASSETS_SUBDIR = 'product-groups';

/**
 * Returns image as Buffer: from assets folder (POSApp/assets/product-groups/<fileName>) if file exists, else from fixture base64.
 */
export function getProductGroupImageBuffer(item: ProductGroupFixtureItem): Buffer {
  if (item.imageFileName) {
    const filePath = path.join(getAssetsPath(), PRODUCT_GROUPS_ASSETS_SUBDIR, item.imageFileName);
    if (fs.existsSync(filePath)) {
      const fileBuffer = fs.readFileSync(filePath);
      return Buffer.from(fileBuffer.toString('base64'), 'base64');
    }
  }
  return Buffer.from(item.imageBase64, 'base64');
}
