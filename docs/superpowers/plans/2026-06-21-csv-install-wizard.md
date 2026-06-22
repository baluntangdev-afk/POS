# CSV Import in Install Wizard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a multi-CSV import wizard page to the Inno Setup installer that seeds the store's product catalog (categories, products, variants) from user-provided CSV files at install time.

**Architecture:** A new `--seed-csv <dir>` CLI flag is added to `POSBackend.exe`. It reads all `.csv` files from the given directory, detects each file's schema by its header row, validates recognized rows, and runs the appropriate seeder. The Inno Setup wizard gets a custom page with a file list and Add/Remove buttons; detected schema and status are shown per file; a warning dialog fires if unknown-schema files are present.

**Tech Stack:** TypeScript · NestJS · TypeORM · PostgreSQL · Inno Setup 6 Pascal Script · PowerShell 5.1

---

## File Map

### Create
- `be/src/database/seeders/csv/csv-schema.registry.ts` — schema enum + `detectSchema(headers)` function; single source of truth for schema detection
- `be/src/database/seeders/csv/csv-parser.ts` — reads a CSV file, handles quoted fields and UTF-8 BOM, returns `{ headers, rows }`
- `be/src/database/seeders/csv/csv-validator.ts` — validates parsed rows per schema type, returns `ValidationError[]`
- `be/src/database/seeders/csv/products-csv.seeder.ts` — 3-pass upsert (categories → products → variants) from parsed CSV rows
- `be/src/database/seeders/csv/run-csv-seeders.ts` — entry point: reads dir, dispatches parse → validate → seed pipeline per file
- `be/src/database/seeders/csv/csv-schema.registry.spec.ts` — unit tests for schema detection
- `be/src/database/seeders/csv/csv-parser.spec.ts` — unit tests for CSV parsing
- `be/src/database/seeders/csv/csv-validator.spec.ts` — unit tests for row validation
- `be/installer/scripts/seed-from-csv.ps1` — PowerShell wrapper that calls `POSBackend.exe --seed-csv`
- `be/installer/scripts/seed-from-csv.bat` — `.bat` shim that delegates to `.ps1`
- `be/installer/products-template.csv` — bundled CSV template with header + example rows

### Modify
- `be/src/exec.ts` — add `--seed-csv <dir>` flag dispatch
- `be/installer/installer.iss` — wizard page code + `[Dirs]` + `[Files]` + `[Run]` step

---

## Task 1: CSV Schema Registry

**Files:**
- Create: `be/src/database/seeders/csv/csv-schema.registry.ts`
- Test: `be/src/database/seeders/csv/csv-schema.registry.spec.ts`

- [ ] **Step 1.1: Write the failing tests**

```typescript
// be/src/database/seeders/csv/csv-schema.registry.spec.ts
import { detectSchema, CsvSchemaType, PRODUCTS_CSV_HEADERS } from './csv-schema.registry';

describe('detectSchema', () => {
  it('detects products/categories/variants schema from exact headers', () => {
    expect(detectSchema(PRODUCTS_CSV_HEADERS)).toBe(CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS);
  });

  it('returns UNKNOWN for an empty array', () => {
    expect(detectSchema([])).toBe(CsvSchemaType.UNKNOWN);
  });

  it('returns UNKNOWN for headers in wrong order', () => {
    const wrong = [...PRODUCTS_CSV_HEADERS].reverse();
    expect(detectSchema(wrong)).toBe(CsvSchemaType.UNKNOWN);
  });

  it('returns UNKNOWN for headers with extra whitespace', () => {
    const withSpace = PRODUCTS_CSV_HEADERS.map(h => ' ' + h);
    expect(detectSchema(withSpace)).toBe(CsvSchemaType.UNKNOWN);
  });

  it('returns UNKNOWN for completely different headers', () => {
    expect(detectSchema(['Name', 'Price', 'Qty'])).toBe(CsvSchemaType.UNKNOWN);
  });
});
```

- [ ] **Step 1.2: Run tests to confirm they fail**

```bash
cd be
npx jest --testPathPattern=csv-schema.registry.spec --no-coverage
```

Expected: FAIL — `Cannot find module './csv-schema.registry'`

- [ ] **Step 1.3: Implement the registry**

```typescript
// be/src/database/seeders/csv/csv-schema.registry.ts
export enum CsvSchemaType {
  PRODUCTS_CATEGORIES_VARIANTS = 'products_categories_variants',
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

const KNOWN_SCHEMAS: Array<{ type: CsvSchemaType; headers: readonly string[] }> = [
  { type: CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS, headers: PRODUCTS_CSV_HEADERS },
];

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
```

- [ ] **Step 1.4: Run tests to confirm they pass**

```bash
npx jest --testPathPattern=csv-schema.registry.spec --no-coverage
```

Expected: PASS (5 tests)

- [ ] **Step 1.5: Commit**

```bash
git add be/src/database/seeders/csv/csv-schema.registry.ts be/src/database/seeders/csv/csv-schema.registry.spec.ts
git commit -m "feat(csv-seed): add CSV schema registry with detectSchema"
```

---

## Task 2: CSV Parser

**Files:**
- Create: `be/src/database/seeders/csv/csv-parser.ts`
- Test: `be/src/database/seeders/csv/csv-parser.spec.ts`

- [ ] **Step 2.1: Write the failing tests**

```typescript
// be/src/database/seeders/csv/csv-parser.spec.ts
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parseCsvFile } from './csv-parser';

function writeTempCsv(content: string): string {
  const file = path.join(os.tmpdir(), `test-${Date.now()}.csv`);
  fs.writeFileSync(file, content, 'utf-8');
  return file;
}

describe('parseCsvFile', () => {
  it('parses headers and rows', () => {
    const file = writeTempCsv('A,B,C\n1,2,3\n4,5,6\n');
    const result = parseCsvFile(file);
    expect(result.headers).toEqual(['A', 'B', 'C']);
    expect(result.rows).toEqual([['1', '2', '3'], ['4', '5', '6']]);
    fs.unlinkSync(file);
  });

  it('handles CRLF line endings', () => {
    const file = writeTempCsv('A,B\r\n1,2\r\n');
    const result = parseCsvFile(file);
    expect(result.headers).toEqual(['A', 'B']);
    expect(result.rows).toEqual([['1', '2']]);
    fs.unlinkSync(file);
  });

  it('handles quoted fields containing commas', () => {
    const file = writeTempCsv('A,B\n"hello, world",2\n');
    const result = parseCsvFile(file);
    expect(result.rows[0][0]).toBe('hello, world');
    fs.unlinkSync(file);
  });

  it('strips UTF-8 BOM', () => {
    const bom = Buffer.from([0xef, 0xbb, 0xbf]);
    const file = path.join(os.tmpdir(), `bom-${Date.now()}.csv`);
    fs.writeFileSync(file, Buffer.concat([bom, Buffer.from('A,B\n1,2\n')]));
    const result = parseCsvFile(file);
    expect(result.headers[0]).toBe('A');
    fs.unlinkSync(file);
  });

  it('skips blank trailing lines', () => {
    const file = writeTempCsv('A,B\n1,2\n\n');
    const result = parseCsvFile(file);
    expect(result.rows).toHaveLength(1);
    fs.unlinkSync(file);
  });

  it('trims whitespace from values', () => {
    const file = writeTempCsv('A , B \n 1 , 2 \n');
    const result = parseCsvFile(file);
    expect(result.headers).toEqual(['A', 'B']);
    expect(result.rows[0]).toEqual(['1', '2']);
    fs.unlinkSync(file);
  });

  it('throws if file does not exist', () => {
    expect(() => parseCsvFile('/no/such/file.csv')).toThrow();
  });
});
```

- [ ] **Step 2.2: Run tests to confirm they fail**

```bash
npx jest --testPathPattern=csv-parser.spec --no-coverage
```

Expected: FAIL — `Cannot find module './csv-parser'`

- [ ] **Step 2.3: Implement the parser**

```typescript
// be/src/database/seeders/csv/csv-parser.ts
import * as fs from 'fs';

export interface ParsedCsv {
  headers: string[];
  rows: string[][];
}

function parseLine(line: string): string[] {
  const fields: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === ',' && !inQuotes) {
      fields.push(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  fields.push(current.trim());
  return fields;
}

export function parseCsvFile(filePath: string): ParsedCsv {
  let content = fs.readFileSync(filePath, 'utf-8');

  // Strip UTF-8 BOM
  if (content.charCodeAt(0) === 0xfeff) {
    content = content.slice(1);
  }

  const lines = content
    .split(/\r?\n/)
    .filter((l) => l.trim() !== '');

  if (lines.length === 0) {
    return { headers: [], rows: [] };
  }

  const headers = parseLine(lines[0]);
  const rows = lines.slice(1).map((l) => parseLine(l));

  return { headers, rows };
}
```

- [ ] **Step 2.4: Run tests to confirm they pass**

```bash
npx jest --testPathPattern=csv-parser.spec --no-coverage
```

Expected: PASS (7 tests)

- [ ] **Step 2.5: Commit**

```bash
git add be/src/database/seeders/csv/csv-parser.ts be/src/database/seeders/csv/csv-parser.spec.ts
git commit -m "feat(csv-seed): add CSV parser with quoted field and BOM support"
```

---

## Task 3: CSV Validator

**Files:**
- Create: `be/src/database/seeders/csv/csv-validator.ts`
- Test: `be/src/database/seeders/csv/csv-validator.spec.ts`

- [ ] **Step 3.1: Write the failing tests**

```typescript
// be/src/database/seeders/csv/csv-validator.spec.ts
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
    expect(validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '120.00', 'Large', '140.00')])).toHaveLength(0);
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
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Product Base Price' }));
  });

  it('errors when Product Base Price is negative', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '-5')]);
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Product Base Price' }));
  });

  it('errors when Variant Name is set but Variant Price is blank', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '120', 'Large', '')]);
    expect(errors).toContainEqual(expect.objectContaining({ row: 2, column: 'Variant Price' }));
  });

  it('errors when Variant Name is set but Variant Price is not a number', () => {
    const errors = validateCsvRows(schema, [row('Coffee', '', 'Latte', '', '120', 'Large', 'free')]);
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
```

- [ ] **Step 3.2: Run tests to confirm they fail**

```bash
npx jest --testPathPattern=csv-validator.spec --no-coverage
```

Expected: FAIL — `Cannot find module './csv-validator'`

- [ ] **Step 3.3: Implement the validator**

```typescript
// be/src/database/seeders/csv/csv-validator.ts
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

export function validateCsvRows(
  schemaType: CsvSchemaType,
  rows: string[][],
): ValidationError[] {
  if (schemaType === CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS) {
    return rows.flatMap((row, i) => validateProductsRow(row, i));
  }
  return [];
}
```

- [ ] **Step 3.4: Run tests to confirm they pass**

```bash
npx jest --testPathPattern=csv-validator.spec --no-coverage
```

Expected: PASS (10 tests)

- [ ] **Step 3.5: Commit**

```bash
git add be/src/database/seeders/csv/csv-validator.ts be/src/database/seeders/csv/csv-validator.spec.ts
git commit -m "feat(csv-seed): add CSV row validator"
```

---

## Task 4: Products CSV Seeder

**Files:**
- Create: `be/src/database/seeders/csv/products-csv.seeder.ts`

No unit tests — depends on a live TypeORM DataSource. Covered by manual verification in Task 5.

- [ ] **Step 4.1: Create the seeder**

```typescript
// be/src/database/seeders/csv/products-csv.seeder.ts
import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import { ProductGroup } from '../../../product-groups/entities/product-group.entity';
import { Product } from '../../../products/entities/product.entity';
import { ProductVariant } from '../../../products/entities/product-variant.entity';
import { ProductStatus, ProductVariantStatus } from '../../../products/products.enum';
import { BaseStatus } from '../../../utils/shared-enums';
import { SeederHelper } from '../../../utils/seeder.helper';

interface CategoryData {
  name: string;
  description: string;
}

interface VariantData {
  name: string;
  price: number;
}

interface ProductData {
  name: string;
  description: string;
  basePrice: number;
  categoryName: string;
  variants: VariantData[];
  sortOrder: number;
}

function groupRows(rows: string[][]): { categories: CategoryData[]; products: ProductData[] } {
  const categoryMap = new Map<string, CategoryData>();
  const productMap = new Map<string, ProductData>();
  let productOrder = 0;

  for (const row of rows) {
    const [category, categoryDesc, productName, productDesc, basePrice, variantName, variantPrice] =
      row;

    if (!categoryMap.has(category)) {
      categoryMap.set(category, { name: category, description: categoryDesc ?? '' });
    }

    const productKey = `${category}::${productName}`;
    if (!productMap.has(productKey)) {
      productMap.set(productKey, {
        name: productName,
        description: productDesc ?? '',
        basePrice: parseFloat(basePrice),
        categoryName: category,
        variants: [],
        sortOrder: productOrder++,
      });
    }

    if (variantName?.trim()) {
      productMap.get(productKey)!.variants.push({
        name: variantName.trim(),
        price: parseFloat(variantPrice),
      });
    }
  }

  return {
    categories: [...categoryMap.values()],
    products: [...productMap.values()],
  };
}

export class ProductsCsvSeeder {
  async run(dataSource: DataSource, rows: string[][]): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const groupRepo = dataSource.getRepository(ProductGroup);
    const productRepo = dataSource.getRepository(Product);
    const variantRepo = dataSource.getRepository(ProductVariant);

    const { categories, products } = groupRows(rows);

    // ── Pass 1: Product Groups (categories) ──────────────────────────────
    const existingGroups = await groupRepo.find({ withDeleted: true });
    const groupByName = new Map(existingGroups.map((g) => [g.name, g]));
    const groupsToInsert: Partial<ProductGroup>[] = [];
    const groupsToUpdate: ProductGroup[] = [];

    for (const cat of categories) {
      const existing = groupByName.get(cat.name);
      if (existing) {
        existing.description = cat.description;
        existing.status = BaseStatus.ACTIVE;
        existing.deletedAt = null;
        existing.updatedBy = adminUser;
        groupsToUpdate.push(existing);
      } else {
        groupsToInsert.push({
          name: cat.name,
          description: cat.description,
          imageUrl: null,
          status: BaseStatus.ACTIVE,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      }
    }

    if (groupsToInsert.length > 0) await groupRepo.save(groupsToInsert);
    if (groupsToUpdate.length > 0) await groupRepo.save(groupsToUpdate);
    console.log(`  Categories: ${groupsToInsert.length} inserted, ${groupsToUpdate.length} updated`);

    // Reload groups with IDs for foreign keys
    const allGroups = await groupRepo.find({ where: { name: In(categories.map((c) => c.name)) } });
    const groupIdByName = new Map(allGroups.map((g) => [g.name, g]));

    // ── Pass 2: Products ──────────────────────────────────────────────────
    const existingProducts = await productRepo.find({
      withDeleted: true,
      relations: { productGroup: true },
    });
    const productByName = new Map(existingProducts.map((p) => [p.name, p]));
    const productsToInsert: Partial<Product>[] = [];
    const productsToUpdate: Product[] = [];

    for (const prod of products) {
      const productGroup = groupIdByName.get(prod.categoryName);
      if (!productGroup) continue;

      const existing = productByName.get(prod.name);
      if (existing) {
        existing.productGroup = productGroup;
        existing.description = prod.description;
        existing.price = prod.basePrice;
        existing.isAvailable = true;
        existing.sortOrder = prod.sortOrder;
        existing.status = ProductStatus.ACTIVE;
        existing.deletedAt = null;
        existing.updatedBy = adminUser;
        productsToUpdate.push(existing);
      } else {
        productsToInsert.push({
          productGroup,
          name: prod.name,
          description: prod.description,
          price: prod.basePrice,
          isAvailable: true,
          sortOrder: prod.sortOrder,
          imageUrl: null,
          status: ProductStatus.ACTIVE,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      }
    }

    if (productsToInsert.length > 0) await productRepo.save(productsToInsert);
    if (productsToUpdate.length > 0) await productRepo.save(productsToUpdate);
    console.log(`  Products: ${productsToInsert.length} inserted, ${productsToUpdate.length} updated`);

    // Reload products with IDs for variant foreign keys
    const allProducts = await productRepo.find({
      where: { name: In(products.map((p) => p.name)) },
    });
    const productIdByName = new Map(allProducts.map((p) => [p.name, p]));

    // ── Pass 3: Product Variants ──────────────────────────────────────────
    const existingVariants = await variantRepo.find({ relations: { product: true } });
    const variantKeySet = new Set(existingVariants.map((v) => `${v.product.id}:${v.name}`));
    const variantsToInsert: Partial<ProductVariant>[] = [];

    for (const prod of products) {
      if (prod.variants.length === 0) continue;
      const product = productIdByName.get(prod.name);
      if (!product) continue;

      prod.variants.forEach((variant, index) => {
        const key = `${product.id}:${variant.name}`;
        if (variantKeySet.has(key)) return;
        variantKeySet.add(key);
        variantsToInsert.push({
          product,
          name: variant.name,
          price: variant.price,
          status: ProductVariantStatus.ACTIVE,
          isDefault: index === 0,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      });
    }

    if (variantsToInsert.length > 0) await variantRepo.save(variantsToInsert);
    console.log(`  Variants: ${variantsToInsert.length} inserted`);
  }
}
```

- [ ] **Step 4.2: Commit**

```bash
git add be/src/database/seeders/csv/products-csv.seeder.ts
git commit -m "feat(csv-seed): add ProductsCsvSeeder with 3-pass upsert"
```

---

## Task 5: CSV Seed Runner

**Files:**
- Create: `be/src/database/seeders/csv/run-csv-seeders.ts`

- [ ] **Step 5.1: Create the runner**

```typescript
// be/src/database/seeders/csv/run-csv-seeders.ts
import * as fs from 'fs';
import * as path from 'path';
import { DataSource } from 'typeorm';
import { typeOrmConfig } from '../../config/typeorm.config';
import { entities } from '../../entities-index';
import { parseCsvFile } from './csv-parser';
import { detectSchema, CsvSchemaType } from './csv-schema.registry';
import { validateCsvRows } from './csv-validator';
import { ProductsCsvSeeder } from './products-csv.seeder';

export async function runCsvSeeders(csvDir: string): Promise<void> {
  if (!fs.existsSync(csvDir)) {
    throw new Error(`CSV directory not found: ${csvDir}`);
  }

  const files = fs
    .readdirSync(csvDir)
    .filter((f) => f.toLowerCase().endsWith('.csv'))
    .sort();

  if (files.length === 0) {
    throw new Error(`No CSV files found in: ${csvDir}`);
  }

  console.log(`Found ${files.length} CSV file(s) in ${csvDir}`);

  const dataSource = new DataSource({
    ...typeOrmConfig,
    entities,
    migrations: [],
  });
  await dataSource.initialize();

  try {
    for (const file of files) {
      const filePath = path.join(csvDir, file);
      console.log(`Processing: ${file}`);

      const parsed = parseCsvFile(filePath);
      const schemaType = detectSchema(parsed.headers);

      if (schemaType === CsvSchemaType.UNKNOWN) {
        console.log(`  Skipping — unknown schema (headers: ${parsed.headers.join(', ')})`);
        continue;
      }

      const errors = validateCsvRows(schemaType, parsed.rows);
      if (errors.length > 0) {
        const errorLines = errors
          .map((e) => `  Row ${e.row}, ${e.column}: ${e.message}`)
          .join('\n');
        throw new Error(`Validation failed in ${file}:\n${errorLines}`);
      }

      if (schemaType === CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS) {
        const seeder = new ProductsCsvSeeder();
        await seeder.run(dataSource, parsed.rows);
      }

      console.log(`  ✓ ${file} seeded (${schemaType})`);
    }
  } finally {
    await dataSource.destroy();
  }

  console.log('CSV seeding completed.');
}
```

- [ ] **Step 5.2: Commit**

```bash
git add be/src/database/seeders/csv/run-csv-seeders.ts
git commit -m "feat(csv-seed): add runCsvSeeders entry point"
```

---

## Task 6: Wire `--seed-csv` into `exec.ts`

**Files:**
- Modify: `be/src/exec.ts`

- [ ] **Step 6.1: Update `exec.ts`**

Replace the entire file content:

```typescript
// be/src/exec.ts
import { runMigrations } from './database/run-migrations';
import { runSeeders } from './database/run-seeders';
import { runCsvSeeders } from './database/seeders/csv/run-csv-seeders';

/**
 * Runs CLI args (e.g. --migrate, --seed, --seed-csv) and returns true if the app should exit without starting the server.
 */
export async function runExecArgs(): Promise<boolean> {
  if (process.argv.includes('--migrate')) {
    await runMigrations();
    return true;
  }

  if (process.argv.includes('--seed')) {
    await runSeeders();
    return true;
  }

  if (process.argv.includes('--seed-csv')) {
    const idx = process.argv.indexOf('--seed-csv');
    const csvDir = process.argv[idx + 1];
    if (!csvDir) {
      throw new Error('--seed-csv requires a directory path argument');
    }
    await runCsvSeeders(csvDir);
    return true;
  }

  return false;
}
```

- [ ] **Step 6.2: Build to verify no TypeScript errors**

```bash
cd be
npm run build
```

Expected: Build succeeds with no errors.

- [ ] **Step 6.3: Manual smoke test**

Create a temp CSV, run the SEA dev build, confirm it exits cleanly:

```bash
# From be/ directory (dev mode, not SEA — uses ts-node)
npx ts-node -r tsconfig-paths/register src/main.ts --seed-csv "C:\path\to\test-csv-dir"
```

Expected: Prints categories/products/variants counts, exits 0.

- [ ] **Step 6.4: Commit**

```bash
git add be/src/exec.ts
git commit -m "feat(csv-seed): wire --seed-csv CLI flag to runCsvSeeders"
```

---

## Task 7: Installer Scripts

**Files:**
- Create: `be/installer/scripts/seed-from-csv.ps1`
- Create: `be/installer/scripts/seed-from-csv.bat`

- [ ] **Step 7.1: Create `seed-from-csv.ps1`**

```powershell
# be/installer/scripts/seed-from-csv.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

$backend    = "$AppDir\backend\POSBackend.exe"
$csvDir     = "$AppDir\data\csv"
$logs       = "$AppDir\logs"
$markerFile = "$logs\seed-csv-success.marker"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

# Remove stale marker from a previous run
if (Test-Path $markerFile) { Remove-Item $markerFile -Force }

Start-Transcript -Path "$logs\seed-csv-install.log" -Force

try {
    Write-Host "AppDir : $AppDir"
    Write-Host "CsvDir : $csvDir"

    if (!(Test-Path $backend)) {
        Write-Error "POSBackend.exe not found at: $backend"
        exit 1
    }

    if (!(Test-Path $csvDir)) {
        Write-Error "CSV directory not found: $csvDir"
        exit 1
    }

    $csvFiles = Get-ChildItem -Path $csvDir -Filter "*.csv" -File
    if ($csvFiles.Count -eq 0) {
        Write-Error "No CSV files found in: $csvDir"
        exit 1
    }

    Write-Host "Found $($csvFiles.Count) CSV file(s). Running CSV seeder..."
    Set-Location "$AppDir\backend"
    & $backend --seed-csv $csvDir

    if ($LASTEXITCODE -ne 0) {
        Write-Error "CSV seeding failed (exit $LASTEXITCODE)"
        exit 1
    }

    # Write success marker so the Inno Setup post-install check can detect success
    [System.IO.File]::WriteAllText($markerFile, "ok")
    Write-Host "seed-from-csv.ps1 completed successfully."

} catch {
    Write-Error "seed-from-csv.ps1 failed: $_"
    exit 1
} finally {
    Stop-Transcript
}
```

- [ ] **Step 7.2: Create `seed-from-csv.bat`**

```bat
@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0seed-from-csv.ps1" -AppDir "%~1"
exit /b %errorlevel%
```

- [ ] **Step 7.3: Commit**

```bash
git add be/installer/scripts/seed-from-csv.ps1 be/installer/scripts/seed-from-csv.bat
git commit -m "feat(installer): add seed-from-csv installer scripts"
```

---

## Task 8: CSV Template File

**Files:**
- Create: `be/installer/products-template.csv`

- [ ] **Step 8.1: Create the template**

```
Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price
Coffee,Hot iced and blended coffee beverages,Espresso,Rich hot espresso shot,110.00,,
Coffee,Hot iced and blended coffee beverages,Cafe Latte,Espresso with steamed milk,165.00,Hot Primo,165.00
Coffee,Hot iced and blended coffee beverages,Cafe Latte,Espresso with steamed milk,165.00,Hot Medio,180.00
Coffee,Hot iced and blended coffee beverages,Cafe Latte,Espresso with steamed milk,165.00,Iced Medio,180.00
Food,Snacks and light meals,Croissant,Buttery flaky pastry,85.00,,
```

Save this file at `be/installer/products-template.csv`.

- [ ] **Step 8.2: Commit**

```bash
git add be/installer/products-template.csv
git commit -m "feat(installer): add products CSV template for store onboarding"
```

---

## Task 9: Inno Setup — Wizard Page

**Files:**
- Modify: `be/installer/installer.iss`

This task adds all Pascal Script `[Code]` changes. The existing `[Code]` section already has `KioskNoPage`, `WaitForServiceStopped`, `InitializeSetup`, `InitializeWizard`, `NextButtonClick`, `ServiceIsRunning`, and `CurStepChanged`. Add new variables and procedures to the same `[Code]` section.

- [ ] **Step 9.1: Add new global variables at the top of `[Code]`**

Find the existing `[Code]` block which starts with:
```pascal
var
  KioskNoPage: TInputQueryWizardPage;
```

Replace that declaration with:

```pascal
var
  KioskNoPage: TInputQueryWizardPage;
  CsvImportPage: TWizardPage;
  CsvListBox: TListBox;
  CsvStatusLabel: TLabel;
  CsvFullPaths: TStringList;
```

- [ ] **Step 9.2: Add helper procedures before `InitializeWizard`**

Insert the following procedures immediately before the `procedure InitializeWizard;` line:

```pascal
// ── CSV Import Page helpers ───────────────────────────────────────────────

const
  PRODUCTS_CSV_HEADER = 'Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price';

function DetectCsvSchema(FilePath: String): String;
var
  Lines: TArrayOfString;
  Header: String;
begin
  Result := 'unknown';
  if not LoadStringsFromFile(FilePath, Lines) then Exit;
  if GetArrayLength(Lines) = 0 then Exit;
  Header := Trim(Lines[0]);
  // Strip UTF-16 BOM if present
  if (Length(Header) > 0) and (Ord(Header[1]) = 65279) then
    Header := Copy(Header, 2, Length(Header));
  if Header = PRODUCTS_CSV_HEADER then
    Result := 'products';
end;

function CountCsvDataRows(FilePath: String): Integer;
var
  Lines: TArrayOfString;
begin
  Result := 0;
  if LoadStringsFromFile(FilePath, Lines) then
    Result := GetArrayLength(Lines) - 1; // minus header
end;

procedure UpdateCsvStatus;
var
  I: Integer;
  FilePath, Schema, DisplayText: String;
  HasKnown, HasErrors: Boolean;
begin
  HasKnown := False;
  HasErrors := False;

  CsvListBox.Items.Clear;

  for I := 0 to CsvFullPaths.Count - 1 do
  begin
    FilePath := CsvFullPaths[I];
    Schema := DetectCsvSchema(FilePath);

    if Schema = 'products' then
    begin
      if CountCsvDataRows(FilePath) > 0 then
      begin
        DisplayText := '[Valid] ' + ExtractFileName(FilePath) + ' — Products / Categories / Variants';
        HasKnown := True;
      end
      else
      begin
        DisplayText := '[Error] ' + ExtractFileName(FilePath) + ' — No data rows found';
        HasErrors := True;
      end;
    end
    else
      DisplayText := '[Warning] ' + ExtractFileName(FilePath) + ' — Unknown schema';

    CsvListBox.Items.Add(DisplayText);
  end;

  if CsvFullPaths.Count = 0 then
    CsvStatusLabel.Caption := 'No CSV files added. At least one recognized CSV is required.'
  else if HasErrors then
    CsvStatusLabel.Caption := 'One or more CSV files have errors. Please fix or remove them.'
  else if not HasKnown then
    CsvStatusLabel.Caption := 'No recognized CSV files. Add a file matching a known schema.'
  else
    CsvStatusLabel.Caption := 'Ready. Recognized CSV files will be imported during installation.';
end;

procedure AddCsvButtonClick(Sender: TObject);
var
  TempScript, TempOutput: String;
  ResultCode, I: Integer;
  Lines: TArrayOfString;
  FilePath, FirstLine: String;
begin
  TempScript := ExpandConstant('{tmp}\open_csv.ps1');
  TempOutput := ExpandConstant('{tmp}\csv_paths.txt');
  DeleteFile(TempOutput);

  SaveStringToFile(TempScript,
    'Add-Type -AssemblyName System.Windows.Forms' + #13#10 +
    '$d = New-Object System.Windows.Forms.OpenFileDialog' + #13#10 +
    '$d.Filter = "CSV files (*.csv)|*.csv"' + #13#10 +
    '$d.Title = "Select CSV files for POS data import"' + #13#10 +
    '$d.Multiselect = $true' + #13#10 +
    'if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {' + #13#10 +
    '  [System.IO.File]::WriteAllLines("' + TempOutput + '", $d.FileNames)' + #13#10 +
    '}',
    False);

  Exec('powershell.exe',
    '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + TempScript + '"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  if FileExists(TempOutput) and LoadStringsFromFile(TempOutput, Lines) then
  begin
    for I := 0 to GetArrayLength(Lines) - 1 do
    begin
      FilePath := Trim(Lines[I]);
      if FilePath = '' then Continue;
      if not FileExists(FilePath) then Continue;
      if CsvFullPaths.IndexOf(FilePath) >= 0 then Continue; // skip duplicates
      CsvFullPaths.Add(FilePath);
    end;
  end;

  UpdateCsvStatus;
end;

procedure RemoveCsvButtonClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CsvListBox.ItemIndex;
  if Idx >= 0 then
  begin
    CsvFullPaths.Delete(Idx);
    UpdateCsvStatus;
  end;
end;
```

- [ ] **Step 9.3: Update `InitializeWizard` to create the CSV page**

Find the existing `procedure InitializeWizard;` block:

```pascal
procedure InitializeWizard;
begin
  KioskNoPage := CreateInputQueryPage(
    wpSelectTasks,
    'Kiosk Configuration',
    'Identify this terminal',
    'Enter a unique kiosk number (1–999) for this machine. ' +
    'It appears in all sales order numbers generated here, e.g. SO-001-2026-0001.'
  );
  KioskNoPage.Add('Kiosk Number:', False);
  KioskNoPage.Values[0] := '1';
end;
```

Replace it with:

```pascal
procedure InitializeWizard;
var
  AddBtn, RemoveBtn: TButton;
  InstructLabel: TLabel;
begin
  // ── Kiosk Number page ─────────────────────────────────────────────────
  KioskNoPage := CreateInputQueryPage(
    wpSelectTasks,
    'Kiosk Configuration',
    'Identify this terminal',
    'Enter a unique kiosk number (1-999) for this machine. ' +
    'It appears in all sales order numbers generated here, e.g. SO-001-2026-0001.'
  );
  KioskNoPage.Add('Kiosk Number:', False);
  KioskNoPage.Values[0] := '1';

  // ── CSV Import page ───────────────────────────────────────────────────
  CsvFullPaths := TStringList.Create;

  CsvImportPage := CreateCustomPage(
    KioskNoPage.ID,
    'Product Catalog Import',
    'Import your store''s product catalog from CSV files'
  );

  InstructLabel := TLabel.Create(CsvImportPage);
  InstructLabel.Parent := CsvImportPage.Surface;
  InstructLabel.Left := 0;
  InstructLabel.Top := 0;
  InstructLabel.Width := CsvImportPage.SurfaceWidth;
  InstructLabel.Caption :=
    'Add one or more CSV files. The installer detects their schema automatically.' + #13#10 +
    'Required schema: Category, Product Name, Product Base Price, Variant Name, Variant Price.' + #13#10 +
    'A template CSV is installed to C:\POSKiosk\data\csv\products-template.csv for reference.';
  InstructLabel.AutoSize := True;
  InstructLabel.WordWrap := True;

  CsvListBox := TListBox.Create(CsvImportPage);
  CsvListBox.Parent := CsvImportPage.Surface;
  CsvListBox.Left := 0;
  CsvListBox.Top := 60;
  CsvListBox.Width := CsvImportPage.SurfaceWidth;
  CsvListBox.Height := 120;

  AddBtn := TButton.Create(CsvImportPage);
  AddBtn.Parent := CsvImportPage.Surface;
  AddBtn.Left := 0;
  AddBtn.Top := 190;
  AddBtn.Width := 100;
  AddBtn.Caption := 'Add CSV...';
  AddBtn.OnClick := @AddCsvButtonClick;

  RemoveBtn := TButton.Create(CsvImportPage);
  RemoveBtn.Parent := CsvImportPage.Surface;
  RemoveBtn.Left := 110;
  RemoveBtn.Top := 190;
  RemoveBtn.Width := 100;
  RemoveBtn.Caption := 'Remove';
  RemoveBtn.OnClick := @RemoveCsvButtonClick;

  CsvStatusLabel := TLabel.Create(CsvImportPage);
  CsvStatusLabel.Parent := CsvImportPage.Surface;
  CsvStatusLabel.Left := 0;
  CsvStatusLabel.Top := 225;
  CsvStatusLabel.Width := CsvImportPage.SurfaceWidth;
  CsvStatusLabel.Caption := 'No CSV files added. At least one recognized CSV is required.';
  CsvStatusLabel.AutoSize := True;
  CsvStatusLabel.WordWrap := True;
end;
```

- [ ] **Step 9.4: Update `NextButtonClick` to validate the CSV page**

Find the existing `function NextButtonClick(CurPageID: Integer): Boolean;` block and add the CSV page check. The full updated function:

```pascal
function NextButtonClick(CurPageID: Integer): Boolean;
var
  KioskNo: String;
  Val, I: Integer;
  UnknownFiles, ErrorFiles: String;
  HasKnown, HasErrors: Boolean;
  FilePath, Schema: String;
  MsgResult: Integer;
begin
  Result := True;

  // ── Kiosk Number validation ───────────────────────────────────────────
  if CurPageID = KioskNoPage.ID then begin
    KioskNo := Trim(KioskNoPage.Values[0]);
    if KioskNo = '' then begin
      MsgBox('Please enter a kiosk number.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    Val := StrToIntDef(KioskNo, 0);
    if (Val < 1) or (Val > 999) then begin
      MsgBox('Kiosk number must be a whole number between 1 and 999.', mbError, MB_OK);
      Result := False;
    end;
  end;

  // ── CSV Import page validation ────────────────────────────────────────
  if CurPageID = CsvImportPage.ID then begin
    HasKnown := False;
    HasErrors := False;
    UnknownFiles := '';
    ErrorFiles := '';

    for I := 0 to CsvFullPaths.Count - 1 do
    begin
      FilePath := CsvFullPaths[I];
      Schema := DetectCsvSchema(FilePath);

      if Schema = 'unknown' then
        UnknownFiles := UnknownFiles + '  - ' + ExtractFileName(FilePath) + #13#10
      else begin
        HasKnown := True;
        if CountCsvDataRows(FilePath) = 0 then begin
          HasErrors := True;
          ErrorFiles := ErrorFiles + '  - ' + ExtractFileName(FilePath) + ' (no data rows)' + #13#10;
        end;
      end;
    end;

    if CsvFullPaths.Count = 0 then begin
      MsgBox('Please add at least one CSV file before continuing.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    if HasErrors then begin
      MsgBox(
        'The following CSV files have errors and must be fixed or removed:' + #13#10 + #13#10 +
        ErrorFiles,
        mbError, MB_OK
      );
      Result := False;
      Exit;
    end;

    if not HasKnown then begin
      MsgBox(
        'None of the added CSV files match a recognized schema.' + #13#10 +
        'At least one recognized CSV file is required to continue.',
        mbError, MB_OK
      );
      Result := False;
      Exit;
    end;

    if UnknownFiles <> '' then begin
      MsgResult := MsgBox(
        'The following files do not match a known schema and will be skipped:' + #13#10 + #13#10 +
        UnknownFiles + #13#10 +
        'Do you want to continue without these files?',
        mbConfirmation, MB_YESNO
      );
      if MsgResult = IDNO then begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;
```

- [ ] **Step 9.5: Update `CurStepChanged` to copy CSV files**

Find the existing `procedure CurStepChanged(CurStep: TSetupStep);` block. Add the CSV copy logic inside the `ssInstall` case. The existing `CurStepChanged` handles `ssPostInstall` and `ssDone`. Add a new block for `ssInstall`:

Locate the start of `CurStepChanged`:
```pascal
procedure CurStepChanged(CurStep: TSetupStep);
var
  SettingsPath: String;
begin
  if CurStep = ssPostInstall then begin
```

Replace with:

```pascal
procedure CurStepChanged(CurStep: TSetupStep);
var
  SettingsPath, CsvDestDir, SrcPath, DestPath: String;
  I: Integer;
begin
  if CurStep = ssInstall then begin
    // Copy all selected CSV files to {app}\data\csv\ before the [Run] steps
    CsvDestDir := ExpandConstant('{app}\data\csv');
    if not DirExists(CsvDestDir) then
      CreateDir(CsvDestDir);
    for I := 0 to CsvFullPaths.Count - 1 do
    begin
      SrcPath := CsvFullPaths[I];
      DestPath := CsvDestDir + '\' + ExtractFileName(SrcPath);
      FileCopy(SrcPath, DestPath, False);
    end;
  end;

  if CurStep = ssPostInstall then begin
    SettingsPath := ExpandConstant('{app}\settings.txt');
    SaveStringToFile(SettingsPath, 'kiosk.no=' + Trim(KioskNoPage.Values[0]), False);

    // Check that CSV seeding completed — the script writes a marker on success.
    // [Run] steps ignore exit codes so this is the only way to surface failures.
    if not FileExists(ExpandConstant('{app}\logs\seed-csv-success.marker')) then begin
      MsgBox(
        'Product catalog import did not complete successfully.' + #13#10 + #13#10 +
        'Check the log for details:' + #13#10 +
        ExpandConstant('{app}\logs\seed-csv-install.log') + #13#10 + #13#10 +
        'You can re-run seeding after install by placing updated CSV files in:' + #13#10 +
        ExpandConstant('{app}\data\csv\') + #13#10 +
        'then running recover-services.bat as administrator.',
        mbError, MB_OK
      );
    end;
```

Make sure to close the `ssPostInstall` block and `ssDone` block as before (do not change that code, just prepend the `ssInstall` block).

- [ ] **Step 9.6: Commit**

```bash
git add be/installer/installer.iss
git commit -m "feat(installer): add multi-CSV import wizard page with schema detection"
```

---

## Task 10: Inno Setup — `[Dirs]`, `[Files]`, `[Run]`

**Files:**
- Modify: `be/installer/installer.iss`

- [ ] **Step 10.1: Add `{app}\data\csv` to `[Dirs]`**

Find:
```
[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\pgsql"
Name: "{app}\nssm"
Name: "{app}\scripts"
```

Replace with:
```
[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\pgsql"
Name: "{app}\nssm"
Name: "{app}\scripts"
Name: "{app}\data\csv"
```

- [ ] **Step 10.2: Add new files to `[Files]`**

Find the `; ── Installer helper scripts` comment block and add two new lines at the end of the scripts block, plus a template line:

After:
```
Source: "scripts\fix-service-recovery.bat";   DestDir: "{app}\scripts"; Flags: ignoreversion
```

Add:
```
Source: "scripts\seed-from-csv.ps1";           DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\seed-from-csv.bat";           DestDir: "{app}\scripts"; Flags: ignoreversion

; ── CSV template ──────────────────────────────────────────────────────────
Source: "..\products-template.csv"; DestDir: "{app}\data\csv"; Flags: ignoreversion onlyifdoesntexist
```

- [ ] **Step 10.3: Add `[Run]` step for CSV seeding**

Find in `[Run]`:
```
; Step 2 — Run TypeORM migrations
;           Logs to: {app}\logs\run-migrations-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\run-migrations.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Running database migrations..."

; NOTE: Seeding is no longer...
```

Add the new step between Step 2 and the NOTE comment:

```
; Step 2 — Run TypeORM migrations
;           Logs to: {app}\logs\run-migrations-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\run-migrations.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Running database migrations..."

; Step 3 — Seed store catalog from imported CSV files
;           Logs to: {app}\logs\seed-csv-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\seed-from-csv.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Importing product catalog from CSV..."

; NOTE: Seeding is no longer...
```

- [ ] **Step 10.4: Commit**

```bash
git add be/installer/installer.iss
git commit -m "feat(installer): wire CSV seeding into [Dirs], [Files], and [Run]"
```

---

## Task 11: End-to-End Verification

- [ ] **Step 11.1: Run all unit tests**

```bash
cd be
npm run test
```

Expected: All tests pass including the 3 new CSV spec files.

- [ ] **Step 11.2: Build the backend SEA**

```bash
npm run build:sea
```

Expected: `be/POSBackend.exe` produced with no errors.

- [ ] **Step 11.3: Smoke-test `--seed-csv` against a real database**

Ensure a local Postgres is running with `pos_db` and migrations applied, then:

```powershell
# From be\installer\
mkdir test-csv
Copy-Item "..\..\..\product-seed-export.csv" "test-csv\products.csv"

.\POSBackend.exe --seed-csv ".\test-csv"
```

Expected output:
```
Found 1 CSV file(s) in .\test-csv
Processing: products.csv
  Categories: N inserted, 0 updated
  Products: N inserted, 0 updated
  Variants: N inserted
  ✓ products.csv seeded (products_categories_variants)
CSV seeding completed.
```

- [ ] **Step 11.4: Test unknown-schema file handling**

Add a second file with wrong headers to the test dir:

```powershell
echo "Foo,Bar,Baz`n1,2,3" > test-csv\unknown.csv
.\POSBackend.exe --seed-csv ".\test-csv"
```

Expected: `Skipping — unknown schema` for `unknown.csv`, seeding continues for `products.csv`.

- [ ] **Step 11.5: Test validation error exits non-zero**

Create a CSV with a bad row (blank Category):

```powershell
echo "Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price`n,Beverages,Latte,Hot latte,120.00,," > test-csv\bad.csv
.\POSBackend.exe --seed-csv ".\test-csv"
echo "Exit code: $LASTEXITCODE"
```

Expected: `Validation failed in bad.csv: Row 2, Category: Category is required`, exit code 1.

- [ ] **Step 11.6: Run `npm run check:quotes` on installer.iss**

```bash
npm run check:quotes
```

Expected: No curly quotes found.

- [ ] **Step 11.7: Commit verification notes to memory (no code change needed)**

No commit required for this task — the tests from Steps 11.1-11.6 are the verification record.
