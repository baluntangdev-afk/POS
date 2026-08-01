import { groupFilesBySchema, ParsedCsvFile } from './run-csv-seeders';
import { CsvSchemaType, PRODUCTS_CSV_HEADERS, MODIFIERS_CSV_HEADERS } from './csv-schema.registry';

const productsFile = (name: string, rows: string[][]): ParsedCsvFile => ({
  name,
  headers: [...PRODUCTS_CSV_HEADERS],
  rows,
});

const modifiersFile = (name: string, rows: string[][]): ParsedCsvFile => ({
  name,
  headers: [...MODIFIERS_CSV_HEADERS],
  rows,
});

describe('groupFilesBySchema', () => {
  it('should merge rows from multiple files of the same schema into one set', () => {
    const fileA = productsFile('new-products-seed.csv', [
      ['Coffee', '', 'Latte', '', '120', 'Small', '120'],
    ]);
    const fileB = productsFile('products-template.csv', [
      ['Tea', '', 'Green Tea', '', '90', 'Small', '90'],
    ]);

    const { grouped, unknownFiles } = groupFilesBySchema([fileA, fileB]);

    expect(unknownFiles).toEqual([]);
    expect(grouped).toHaveLength(1);
    const products = grouped[0];
    expect(products.schemaType).toBe(CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS);
    expect(products.files).toEqual(['new-products-seed.csv', 'products-template.csv']);
    // Both files' rows are combined so neither clobbers the other.
    expect(products.rows).toEqual([
      ['Coffee', '', 'Latte', '', '120', 'Small', '120'],
      ['Tea', '', 'Green Tea', '', '90', 'Small', '90'],
    ]);
  });

  it('should keep different schemas in separate groups', () => {
    const products = productsFile('products.csv', [['Coffee', '', 'Latte', '', '120', '', '']]);
    const modifiers = modifiersFile('modifiers.csv', [
      ['Milk', '', 'single', 'false', '0', '1', '', 'Whole', '0', 'true'],
    ]);

    const { grouped } = groupFilesBySchema([products, modifiers]);

    expect(grouped).toHaveLength(2);
    const byType = new Map(grouped.map((g) => [g.schemaType, g]));
    expect(byType.get(CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS)!.rows).toHaveLength(1);
    expect(byType.get(CsvSchemaType.MODIFIERS)!.rows).toHaveLength(1);
  });

  it('should report unknown-schema files separately and exclude them from groups', () => {
    const known = productsFile('products.csv', [['Coffee', '', 'Latte', '', '120', '', '']]);
    const unknown: ParsedCsvFile = {
      name: 'random.csv',
      headers: ['foo', 'bar'],
      rows: [['1', '2']],
    };

    const { grouped, unknownFiles } = groupFilesBySchema([known, unknown]);

    expect(unknownFiles).toEqual(['random.csv']);
    expect(grouped).toHaveLength(1);
    expect(grouped[0].schemaType).toBe(CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS);
  });
});
