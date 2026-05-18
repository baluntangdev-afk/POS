import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { MaterialType } from '../../material-types/entities/material-type.entity';
import { BaseStatus } from '../../utils/shared-enums';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { MATERIAL_TYPES_FIXTURE } from './fixtures/material-types.fixture';

/**
 * Seeder: MaterialTypesSeeder
 */
export class MaterialTypesSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const data = this.getData(adminUser);
    const repo = dataSource.getRepository(MaterialType);

    const existingCodes = await repo
      .createQueryBuilder('mt')
      .select('mt.materialTypeCode')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.materialTypeCode)));

    const toInsert = data.filter((d) => !existingCodes.has(d.materialTypeCode!));
    if (toInsert.length === 0) {
      console.log('Material types already seeded, skip');
      return;
    }

    const persistedData = await repo.save(toInsert);
    await repo.save(persistedData);
    console.log(`${persistedData.length} material types seeded`);
  }

  private getData(adminUser: User): Partial<MaterialType>[] {
    const base = { status: BaseStatus.ACTIVE, createdBy: adminUser, updatedBy: adminUser };

    return MATERIAL_TYPES_FIXTURE.map((item) => ({
      ...base,
      ...item,
    }));
  }
}
