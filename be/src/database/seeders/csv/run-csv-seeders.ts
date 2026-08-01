import * as fs from 'fs';
import * as path from 'path';
import { DataSource } from 'typeorm';
import { typeOrmConfig } from '../../config/typeorm.config';
import { entities } from '../../entities-index';
import { parseCsvFile } from './csv-parser';
import { detectSchema, CsvSchemaType } from './csv-schema.registry';
import { validateCsvRows } from './csv-validator';
import { ProductsCsvSeeder } from './products-csv.seeder';
import { ModifiersCsvSeeder } from './modifiers-csv.seeder';

export interface ParsedCsvFile {
  name: string;
  headers: string[];
  rows: string[][];
}

export interface GroupedCsvData {
  schemaType: CsvSchemaType;
  /** Names of the files (in input order) whose rows were merged into this group. */
  files: string[];
  /** All recognized files' rows for this schema, concatenated in input order. */
  rows: string[][];
}

/**
 * Merges every file that shares a schema into a single row set. This is what
 * makes the importer safe when the install directory contains more than one file
 * of the same kind (e.g. two product CSVs): the seeders treat their input as the
 * authoritative catalog and soft-delete anything absent from it, so feeding them
 * file-by-file makes each file delete the previous file's rows. By concatenating
 * first, the *union* of all imported files becomes the source of truth — existing
 * data not present in ANY imported file is removed, and every imported file's
 * rows are applied together. Files with an unrecognized header are returned in
 * `unknownFiles` and contribute no rows.
 */
export function groupFilesBySchema(parsedFiles: ParsedCsvFile[]): {
  grouped: GroupedCsvData[];
  unknownFiles: string[];
} {
  const bySchema = new Map<CsvSchemaType, GroupedCsvData>();
  const unknownFiles: string[] = [];

  for (const file of parsedFiles) {
    const schemaType = detectSchema(file.headers);
    if (schemaType === CsvSchemaType.UNKNOWN) {
      unknownFiles.push(file.name);
      continue;
    }

    let group = bySchema.get(schemaType);
    if (!group) {
      group = { schemaType, files: [], rows: [] };
      bySchema.set(schemaType, group);
    }
    group.files.push(file.name);
    group.rows.push(...file.rows);
  }

  return { grouped: [...bySchema.values()], unknownFiles };
}

/**
 * Entry point for `POSBackend.exe --seed-csv <dir>`. Reads every `.csv` file in
 * the directory, detects each file's schema, validates recognized files, then
 * seeds each schema ONCE using the merged rows from all files of that schema.
 * Each seeder makes the imported data authoritative — existing rows not present
 * in any imported CSV are soft-deleted, and the imported rows are upserted.
 * Unknown-schema files are skipped with a log line (the installer wizard already
 * warned the user). A validation error aborts with a non-zero exit so the
 * installer can surface the failure.
 */
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

  // Parse + validate every file before touching the database, so a bad file
  // aborts the whole import rather than leaving a half-applied catalog.
  const parsedFiles: ParsedCsvFile[] = [];
  for (const file of files) {
    const filePath = path.join(csvDir, file);
    const parsed = parseCsvFile(filePath);
    const schemaType = detectSchema(parsed.headers);

    if (schemaType === CsvSchemaType.UNKNOWN) {
      console.log(`  Skipping ${file} — unknown schema (headers: ${parsed.headers.join(', ')})`);
      continue;
    }

    const errors = validateCsvRows(schemaType, parsed.rows);
    if (errors.length > 0) {
      const errorLines = errors.map((e) => `  Row ${e.row}, ${e.column}: ${e.message}`).join('\n');
      throw new Error(`Validation failed in ${file}:\n${errorLines}`);
    }

    parsedFiles.push({ name: file, headers: parsed.headers, rows: parsed.rows });
  }

  const { grouped } = groupFilesBySchema(parsedFiles);

  if (grouped.length === 0) {
    console.log('No recognized CSV files to seed.');
    return;
  }

  const dataSource = new DataSource({
    ...typeOrmConfig,
    entities,
    migrations: [],
  });
  await dataSource.initialize();

  try {
    for (const group of grouped) {
      console.log(
        `Seeding ${group.schemaType} from ${group.files.length} file(s): ${group.files.join(', ')}`,
      );

      if (group.schemaType === CsvSchemaType.PRODUCTS_CATEGORIES_VARIANTS) {
        const seeder = new ProductsCsvSeeder();
        await seeder.run(dataSource, group.rows);
      } else if (group.schemaType === CsvSchemaType.MODIFIERS) {
        const seeder = new ModifiersCsvSeeder();
        await seeder.run(dataSource, group.rows);
      }

      console.log(`  ✓ ${group.schemaType} seeded`);
    }
  } finally {
    await dataSource.destroy();
  }

  console.log('CSV seeding completed.');
}
