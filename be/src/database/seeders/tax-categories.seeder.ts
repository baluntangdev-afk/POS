import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { TaxCategory } from '../../tax-categories/entities/tax-category.entity';
import { TAX_CATEGORIES_FIXTURE } from './fixtures/tax-categories.fixture';

/**
 * Seeder: TaxCategoriesSeeder
 */
export class TaxCategoriesSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const data = TAX_CATEGORIES_FIXTURE;
    const repo = dataSource.getRepository(TaxCategory);

    const existingNames = await repo
      .createQueryBuilder('tc')
      .select('tc.name')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.name)));

    const toInsert = data.filter((d) => !existingNames.has(d.name));
    if (toInsert.length === 0) {
      console.log('Tax categories already seeded, skip');
      return;
    }

    await repo.save(toInsert as Partial<TaxCategory>[]);
    console.log(`${toInsert.length} tax categories seeded`);
  }
}
