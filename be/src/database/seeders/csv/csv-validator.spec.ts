import { validateCsvRows, ValidationError } from './csv-validator';
import { CsvSchemaType } from './csv-schema.registry';

// Helper: builds a valid products row
function row(
  category = 'Coffee',
  categoryDesc = 'Beverages',
  productName = 'Latte',
  productDesc = 'Hot latte',
  basePrice = '120.00',
  variantName = '',
  variantPrice = '',
): string[] {
  return [category, categoryDesc, productName, productDesc, basePrice, variantName, variantPrice];
}

describe('validateCsvRows (PRODUCTS_CATEGORIES_VARIANTS)', () => {
  const schema = CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS;

  it('returns no errors for a valid row without variants', () => {
    expect(validateCsvRows(schema, [row()])).toHaveLength(0);
  });

  it('returns no errors for a valid row with a variant', () => {
    expect(
      validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '120.00', 'Large', '140.00')]),
    ).toHaveLength(0);
  });

  it('errors when Category is blank', () => {
    const errors: ValidationError[] = validateCsvRows(schema, [row('')]);
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Category' }));
  });

  it('errors when Product Name is blank', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', '')]);
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Product Name' }));
  });

  it('errors when Product Base Price is not a number', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', 'Latte', '', 'abc')]);
    expect(errors).toContainEqual(
      expect.objectContaining({ row: 2, column: 'Product Base Price' }),
    );
  });

  it('errors when Product Base Price is negative', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '-5')]);
    expect(errors).toContainEqual(
      expect.objectContaining({ row: 2, column: 'Product Base Price' }),
    );
  });

  it('errors when Variant Name is set but Variant Price is blank', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '120', 'Large', '')]);
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Variant Price' }));
  });

  it('errors when Variant Name is set but Variant Price is not a number', () => {
    const errors = validateCsvRows(schema, [
      row('Coffee', '', 'Latte', '', '120', 'Large', 'free'),
    ]);
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Variant Price' }));
  });

  it('reports row numbers starting at 2 (header is row 1)', () => {
    const errors = validateCsvRows(schema, [row(), row('')]);
    expect(errors[0].row).toBe(3);
  });

  it('accumulates errors across multiple rows', () => {
    const errors = validateCsvRows(schema, [row(''), row('', '', '')]);
    expect(errors.length).toBeGreaterThan(1);
  });
});

// Helper: builds a valid modifier row
function mrow(
  groupName = 'Size',
  groupDesc = 'Choose your size',
  selectionType = 'single',
  isRequired = 'true',
  minSel = '1',
  maxSel = '1',
  linkedGroup = '',
  optionName = 'Large',
  optionPrice = '25.00',
  optionAvailable = 'true',
): string[] {
  return [
    groupName,
    groupDesc,
    selectionType,
    isRequired,
    minSel,
    maxSel,
    linkedGroup,
    optionName,
    optionPrice,
    optionAvailable,
  ];
}

describe('validateCsvRows (MODIFIERS)', () => {
  const schema = CsvSchemaType.MODIFIERS;

  it('returns no errors for a valid single-selection row', () => {
    expect(validateCsvRows(schema, [mrow()])).toHaveLength(0);
  });

  it('returns no errors for a valid multiple-selection row', () => {
    expect(
      validateCsvRows(schema, [
        mrow('Add-Ons', 'Customise', 'multiple', 'false', '0', '5', '', 'Bacon', '25.00', 'true'),
      ]),
    ).toHaveLength(0);
  });

  it('errors when Modifier Group Name is blank', () => {
    expect(validateCsvRows(schema, [mrow('')])).toContainEqual(
      expect.objectContaining({ row: 2, column: 'Modifier Group Name' }),
    );
  });

  it('errors on invalid Selection Type', () => {
    expect(validateCsvRows(schema, [mrow('Size', '', 'maybe')])).toContainEqual(
      expect.objectContaining({ row: 2, column: 'Selection Type' }),
    );
  });

  it('errors on non-boolean Is Required', () => {
    expect(validateCsvRows(schema, [mrow('Size', '', 'single', 'yes')])).toContainEqual(
      expect.objectContaining({ row: 2, column: 'Is Required' }),
    );
  });

  it('errors on non-integer Min Selection', () => {
    expect(validateCsvRows(schema, [mrow('Size', '', 'single', 'true', '1.5')])).toContainEqual(
      expect.objectContaining({ row: 2, column: 'Min Selection' }),
    );
  });

  it('errors when Max Selection is less than Min Selection', () => {
    expect(
      validateCsvRows(schema, [mrow('Size', '', 'single', 'true', '3', '1')]),
    ).toContainEqual(expect.objectContaining({ row: 2, column: 'Max Selection' }));
  });

  it('errors when Option Name is blank', () => {
    expect(
      validateCsvRows(schema, [mrow('Size', '', 'single', 'true', '1', '1', '', '')]),
    ).toContainEqual(expect.objectContaining({ row: 2, column: 'Option Name' }));
  });

  it('errors on invalid Option Price Add-On', () => {
    expect(
      validateCsvRows(schema, [mrow('Size', '', 'single', 'true', '1', '1', '', 'Large', 'free')]),
    ).toContainEqual(expect.objectContaining({ row: 2, column: 'Option Price Add-On' }));
  });

  it('errors on non-boolean Option Available', () => {
    expect(
      validateCsvRows(schema, [
        mrow('Size', '', 'single', 'true', '1', '1', '', 'Large', '25.00', 'maybe'),
      ]),
    ).toContainEqual(expect.objectContaining({ row: 2, column: 'Option Available' }));
  });

  it('accepts a blank Linked Product Group (ignored column)', () => {
    expect(
      validateCsvRows(schema, [
        mrow('Size', '', 'single', 'true', '1', '1', '(not linked in seeds)', 'Large', '25.00', 'true'),
      ]),
    ).toHaveLength(0);
  });
});
