import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Currency } from '../../currencies/entities/currency.entity';
import { CURRENCIES_FIXTURE } from './fixtures/currencies.fixture';

/**
 * Seeder: CurrenciesSeeder
 */
export class CurrenciesSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const repo = dataSource.getRepository(Currency);
    const existingCodes = await repo
      .createQueryBuilder('c')
      .select('c.code')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.code)));
    const toInsert = CURRENCIES_FIXTURE.filter((d) => !existingCodes.has(d.code));
    if (toInsert.length === 0) {
      console.log('Currencies already seeded, skip');
      return;
    }
    const hasNewDefault = toInsert.some((d) => d.isDefault);
    if (hasNewDefault) {
      await repo.update({ isDefault: true }, { isDefault: false });
    }
    const data = toInsert.map((item) => ({
      code: item.code,
      name: item.name,
      sign: item.sign,
      isDefault: item.isDefault,
    }));
    await repo.save(data);
    console.log(`${data.length} currencies seeded`);
  }
}
