import { CsvSchemaType } from './csv-schema.registry';

export interface ValidationError {
  row: number;
  column: string;
  message: string;
}

function isNonNegativeNumber(value: string): boolean {
  const n = parseFloat(value);
  return !isNaN(n) && isFinite(n) && n >= 0;
}

function isNonNegativeInteger(value: string): boolean {
  return /^\d+$/.test(value.trim());
}

function isBoolean(value: string): boolean {
  const v = value.trim().toLowerCase();
  return v === 'true' || v === 'false';
}

function validateProductsRow(row: string[], rowIndex: number): ValidationError[] {
  const errors: ValidationError[] = [];
  const displayRow = rowIndex + 2; // +1 for header, +1 for 0-index
  const [category, , productName, , basePrice, variantName, variantPrice] = row;

  if (!category?.trim()) {
    errors.push({ row: displayRow, column: 'Category', message: 'Category is required' });
  }
  if (!productName?.trim()) {
    errors.push({ row: displayRow, column: 'Product Name', message: 'Product Name is required' });
  }
  if (!basePrice?.trim() || !isNonNegativeNumber(basePrice.trim())) {
    errors.push({
      row: displayRow,
      column: 'Product Base Price',
      message: 'Must be a valid number >= 0',
    });
  }
  if (variantName?.trim()) {
    if (!variantPrice?.trim() || !isNonNegativeNumber(variantPrice.trim())) {
      errors.push({
        row: displayRow,
        column: 'Variant Price',
        message: 'Required when Variant Name is present; must be a valid number >= 0',
      });
    }
  }

  return errors;
}

function validateModifiersRow(row: string[], rowIndex: number): ValidationError[] {
  const errors: ValidationError[] = [];
  const displayRow = rowIndex + 2; // +1 for header, +1 for 0-index
  const [
    groupName,
    ,
    selectionType,
    isRequired,
    minSelection,
    maxSelection,
    ,
    optionName,
    optionPrice,
    optionAvailable,
  ] = row;

  if (!groupName?.trim()) {
    errors.push({ row: displayRow, column: 'Modifier Group Name', message: 'Required' });
  }

  const sel = selectionType?.trim().toLowerCase();
  if (sel !== 'single' && sel !== 'multiple') {
    errors.push({
      row: displayRow,
      column: 'Selection Type',
      message: "Must be 'single' or 'multiple'",
    });
  }

  if (!isRequired?.trim() || !isBoolean(isRequired)) {
    errors.push({ row: displayRow, column: 'Is Required', message: "Must be 'true' or 'false'" });
  }

  const minOk = isNonNegativeInteger(minSelection ?? '');
  if (!minOk) {
    errors.push({ row: displayRow, column: 'Min Selection', message: 'Must be an integer >= 0' });
  }
  const maxOk = isNonNegativeInteger(maxSelection ?? '');
  if (!maxOk) {
    errors.push({ row: displayRow, column: 'Max Selection', message: 'Must be an integer >= 0' });
  }
  if (minOk && maxOk && parseInt(maxSelection, 10) < parseInt(minSelection, 10)) {
    errors.push({
      row: displayRow,
      column: 'Max Selection',
      message: 'Must be >= Min Selection',
    });
  }

  if (!optionName?.trim()) {
    errors.push({ row: displayRow, column: 'Option Name', message: 'Required' });
  }

  if (!optionPrice?.trim() || !isNonNegativeNumber(optionPrice.trim())) {
    errors.push({
      row: displayRow,
      column: 'Option Price Add-On',
      message: 'Must be a valid number >= 0',
    });
  }

  if (!optionAvailable?.trim() || !isBoolean(optionAvailable)) {
    errors.push({
      row: displayRow,
      column: 'Option Available',
      message: "Must be 'true' or 'false'",
    });
  }

  return errors;
}

/**
 * Validates parsed CSV rows against the rules for their schema type. Returns an
 * empty array when all rows are valid. Row numbers are 1-based and account for
 * the header line, so they match what the user sees in a spreadsheet editor.
 */
export function validateCsvRows(schemaType: CsvSchemaType, rows: string[][]): ValidationError[] {
  if (schemaType === CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS) {
    return rows.flatMap((row, i) => validateProductsRow(row, i));
  }
  if (schemaType === CsvSchemaType.MODIFIERS) {
    return rows.flatMap((row, i) => validateModifiersRow(row, i));
  }
  return [];
}
