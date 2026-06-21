import { detectSchema, CsvSchemaType, PRODUCTS_CSV_HEADERS } from './csv-schema.registry';

describe('detectSchema', () => {
  it('detects products/categories/variants schema from exact headers', () => {
    expect(detectSchema([...PRODUCTS_CSV_HEADERS])).toBe(
      CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS,
    );
  });

  it('returns UNKNOWN for an empty array', () => {
    expect(detectSchema([])).toBe(CsvSchemaType.UNKNOWN);
  });

  it('returns UNKNOWN for headers in wrong order', () => {
    const wrong = [...PRODUCTS_CSV_HEADERS].reverse();
    expect(detectSchema(wrong)).toBe(CsvSchemaType.UNKNOWN);
  });

  it('returns UNKNOWN for headers with extra whitespace', () => {
    const withSpace = PRODUCTS_CSV_HEADERS.map((h) => ' ' + h);
    expect(detectSchema(withSpace)).toBe(CsvSchemaType.UNKNOWN);
  });

  it('returns UNKNOWN for completely different headers', () => {
    expect(detectSchema(['Name', 'Price', 'Qty'])).toBe(CsvSchemaType.UNKNOWN);
  });
});
