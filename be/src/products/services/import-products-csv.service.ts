import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { parseCsvContent } from '../../database/seeders/csv/csv-parser';
import { CsvSchemaType, detectSchema } from '../../database/seeders/csv/csv-schema.registry';
import { validateCsvRows } from '../../database/seeders/csv/csv-validator';
import {
  ProductsCsvSeeder,
  ProductsCsvSeedSummary,
} from '../../database/seeders/csv/products-csv.seeder';

export type ImportProductsCsvMode = 'upsert' | 'replace';

@Injectable()
export class ImportProductsCsvService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async execute(fileContent: string, mode: ImportProductsCsvMode): Promise<ProductsCsvSeedSummary> {
    const { headers, rows } = parseCsvContent(fileContent);
    const schemaType = detectSchema(headers);

    if (schemaType === CsvSchemaType.UNKNOWN) {
      throw new BadRequestException(
        'File does not match the expected products/categories/variants CSV format.',
      );
    }
    if (schemaType === CsvSchemaType.MODIFIERS) {
      throw new BadRequestException('Modifiers CSV import is not supported from this endpoint.');
    }

    const errors = validateCsvRows(schemaType, rows);
    if (errors.length > 0) {
      throw new BadRequestException({ message: 'CSV validation failed', errors });
    }

    const seeder = new ProductsCsvSeeder();
    return seeder.run(this.dataSource, rows, { authoritative: mode === 'replace' });
  }
}
