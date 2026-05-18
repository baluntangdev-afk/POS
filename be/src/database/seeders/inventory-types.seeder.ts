import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { InventoryCountType } from '../../inventory-counts/entities/inventory-count-type.entity';
import { INVENTORY_COUNT_TYPES_FIXTURE } from './fixtures/inventory-count-types.fixture';

/**
 * Seeder: InventoryTypesSeeder
 */
export class InventoryTypesSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const repo = dataSource.getRepository(InventoryCountType);

    const existingNames = await repo
      .createQueryBuilder('ict')
      .select('ict.name')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.name)));

    const toInsert = INVENTORY_COUNT_TYPES_FIXTURE.filter((d) => !existingNames.has(d.name));
    if (toInsert.length === 0) {
      console.log('Inventory count types already seeded, skip');
      return;
    }

    await repo.save(toInsert);
    console.log(`${toInsert.length} inventory count types seeded`);
  }
}
