import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Uom } from '../../uom/entities/uom.entity';
import { BaseStatus } from '../../utils/shared-enums';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { UOM_FIXTURE } from './fixtures/uom.fixture';

/**
 * Seeder: UomSeeder
 */
export class UomSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const data = this.getData(adminUser);
    const repo = dataSource.getRepository(Uom);

    const existingCodes = await repo
      .createQueryBuilder('u')
      .select('u.code')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.code)));

    const toInsert = data.filter((d) => !existingCodes.has(d.code!));
    if (toInsert.length === 0) {
      console.log('UOMs already seeded, skip');
      return;
    }

    const persistedData = await repo.save(toInsert);
    await repo.save(persistedData);
    console.log(`${persistedData.length} UOMs seeded`);
  }

  private getData(adminUser: User): Partial<Uom>[] {
    const base = { status: BaseStatus.ACTIVE, createdBy: adminUser, updatedBy: adminUser };

    return UOM_FIXTURE.map((item) => ({
      ...base,
      ...item,
    }));
  }
}
