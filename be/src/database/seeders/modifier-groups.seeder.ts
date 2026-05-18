import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { MODIFIER_GROUPS_FIXTURE } from './fixtures/modifier-groups.fixture';

/**
 * Seeder: ModifierGroupsSeeder
 */
export class ModifierGroupsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const data = this.getData(adminUser);
    const repo = dataSource.getRepository(ModifierGroup);
    const existingNames = await repo
      .createQueryBuilder('mg')
      .select('mg.name')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.name)));
    const toInsert = data.filter((d) => !existingNames.has(d.name!));
    if (toInsert.length === 0) {
      console.log('Modifier groups already seeded, skip');
      return;
    }
    const persistedData = await repo.save(toInsert);
    await repo.save(persistedData);
    console.log(`${persistedData.length} modifier groups seeded`);
  }

  private getData(adminUser: User): Partial<ModifierGroup>[] {
    const base = { createdBy: adminUser, updatedBy: adminUser };
    return MODIFIER_GROUPS_FIXTURE.map((item) => ({
      ...base,
      name: item.name,
      minSelection: item.minSelection ?? 0,
      maxSelection: item.maxSelection ?? 1,
    }));
  }
}
