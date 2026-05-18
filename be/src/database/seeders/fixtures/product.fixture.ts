import * as fs from 'fs';
import * as path from 'path';
import { getAssetsPath } from '../../../utils/path.helper';

/**
 * Product seed data with optional image file or random image from assets/products.
 * When imageFileName is set and exists under assets/products/, it is used; otherwise a random image from that folder is selected.
 */
export interface ProductFixtureItem {
  name: string;
  groupName: 'Beverages' | 'Dessert' | 'Meals' | 'Sandwiches';
  description: string;
  /** Filename (no path) for optional file under assets/products/. If omitted, a random file from assets/products is used. */
  imageFileName?: string;
  /** Base64-encoded image fallback when no file is available. Decoded to bytea in the entity. */
  imageBase64: string;
}

/** 1x1 transparent PNG (~67 bytes) – fallback when asset file is missing */
const TINY_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

/**
 * Products for ProductsSeeder: beverages (random image from beverage-products), dessert (muffin), meals (salad), sandwiches (club sandwich).
 */
export const PRODUCTS_SEEDER_FIXTURE: ProductFixtureItem[] = [
  { name: 'Latte', groupName: 'Beverages', description: 'Latte', imageBase64: TINY_PNG_BASE64 },
  {
    name: 'Americano',
    groupName: 'Beverages',
    description: 'Americano',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Macchiato',
    groupName: 'Beverages',
    description: 'Macchiato',
    imageBase64: TINY_PNG_BASE64,
  },
  { name: 'Matcha', groupName: 'Beverages', description: 'Matcha', imageBase64: TINY_PNG_BASE64 },
  {
    name: 'Muffin',
    groupName: 'Dessert',
    description: 'Muffin',
    imageFileName: 'muffin.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Salad',
    groupName: 'Meals',
    description: 'Salad',
    imageFileName: 'salad.png',
    imageBase64: TINY_PNG_BASE64,
  },
  {
    name: 'Club Sandwich',
    groupName: 'Sandwiches',
    description: 'Club Sandwich',
    imageFileName: 'sandwich.png',
    imageBase64: TINY_PNG_BASE64,
  },
];

const ASSETS_SUBDIR_BY_GROUP: Record<ProductFixtureItem['groupName'], string> = {
  Beverages: 'beverage-products',
  Dessert: 'dessert-products',
  Meals: 'meals-products',
  Sandwiches: 'sandwiches-products',
};

/**
 * Returns image as Buffer: from item.imageFileName if set and file exists under the group's assets folder; otherwise a random file from that folder; else fixture base64.
 */
export function getProductImageBuffer(item: ProductFixtureItem): Buffer {
  const assetsSubdir = ASSETS_SUBDIR_BY_GROUP[item.groupName];
  const dirPath = path.join(getAssetsPath(), assetsSubdir);
  if (item.imageFileName) {
    const filePath = path.join(dirPath, item.imageFileName);
    if (fs.existsSync(filePath)) {
      const fileBuffer = fs.readFileSync(filePath);
      return Buffer.from(fileBuffer.toString('base64'), 'base64');
    }
  }
  if (fs.existsSync(dirPath)) {
    const files = fs.readdirSync(dirPath).filter((f) => /\.(png|jpg|jpeg|gif|webp)$/i.test(f));
    if (files.length > 0) {
      const randomFile = files[Math.floor(Math.random() * files.length)];
      const fileBuffer = fs.readFileSync(path.join(dirPath, randomFile));
      return Buffer.from(fileBuffer.toString('base64'), 'base64');
    }
  }
  return Buffer.from(item.imageBase64, 'base64');
}
