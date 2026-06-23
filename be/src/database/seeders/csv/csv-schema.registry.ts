export enum CsvSchemaType {
  PRODUCTS_CATEGORIES_VARIANTS = 'products_categories_variants',
  MODIFIERS = 'modifiers',
  UNKNOWN = 'unknown',
}

export const PRODUCTS_CSV_HEADERS = [
  'Category',
  'Category Description',
  'Product Name',
  'Product Description',
  'Product Base Price',
  'Variant Name',
  'Variant Price',
] as const;

/** Optional trailing product-level column for an image URL. */
export const PRODUCT_IMAGE_URL_HEADER = 'Product Image URL';

/**
 * Products schema variant with the optional `Product Image URL` column appended.
 * Files exported before this column existed (7 columns) remain valid; files that
 * include the image column (8 columns) are detected as the same schema type.
 */
export const PRODUCTS_CSV_HEADERS_WITH_IMAGE = [
  ...PRODUCTS_CSV_HEADERS,
  PRODUCT_IMAGE_URL_HEADER,
] as const;

export const MODIFIERS_CSV_HEADERS = [
  'Modifier Group Name',
  'Group Description',
  'Selection Type',
  'Is Required',
  'Min Selection',
  'Max Selection',
  'Linked Product Group',
  'Option Name',
  'Option Price Add-On',
  'Option Available',
] as const;

const KNOWN_SCHEMAS: Array<{ type: CsvSchemaType; headers: readonly string[] }> = [
  { type: CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS, headers: PRODUCTS_CSV_HEADERS },
  { type: CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS, headers: PRODUCTS_CSV_HEADERS_WITH_IMAGE },
  { type: CsvSchemaType.MODIFIERS, headers: MODIFIERS_CSV_HEADERS },
];

/**
 * Identifies a CSV's schema by matching its header row exactly (order and
 * spelling) against the known schemas. Detection must be authoritative: it is
 * shared conceptually with the installer wizard, so a header that does not match
 * a known schema is reported as UNKNOWN rather than guessed.
 */
export function detectSchema(headers: string[]): CsvSchemaType {
  for (const schema of KNOWN_SCHEMAS) {
    if (
      headers.length === schema.headers.length &&
      headers.every((h, i) => h === schema.headers[i])
    ) {
      return schema.type;
    }
  }
  return CsvSchemaType.UNKNOWN;
}
