import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { MODIFIER_GROUPS_FIXTURE } from './fixtures/modifier-groups.fixture';

export class ModifierGroupsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const repo = dataSource.getRepository(ModifierGroup);

    const existingGroups = await repo.find({ withDeleted: true });
    const existingByName = new Map(existingGroups.map((g) => [g.name.toLowerCase(), g]));

    const toInsert: Partial<ModifierGroup>[] = [];
    const toUpdate: ModifierGroup[] = [];

    for (const item of MODIFIER_GROUPS_FIXTURE) {
      const existing = existingByName.get(item.name.toLowerCase());
      if (existing) {
        existing.name = item.name;
        existing.description = item.description;
        existing.selectionType = item.selectionType;
        existing.isRequired = item.isRequired;
        existing.minSelection = item.minSelection;
        existing.maxSelection = item.maxSelection;
        existing.deletedAt = null;
        existing.updatedBy = adminUser;
        toUpdate.push(existing);
      } else {
        toInsert.push(this.buildGroup(adminUser, item));
      }
    }

    if (toInsert.length > 0) await repo.save(toInsert);
    if (toUpdate.length > 0) await repo.save(toUpdate);

    console.log(
      `Modifier groups: ${toInsert.length} inserted, ${toUpdate.length} updated`,
    );
  }

  private buildGroup(adminUser: User, item: (typeof MODIFIER_GROUPS_FIXTURE)[number]): Partial<ModifierGroup> {
    return {
      name: item.name,
      description: item.description,
      selectionType: item.selectionType,
      isRequired: item.isRequired,
      minSelection: item.minSelection,
      maxSelection: item.maxSelection,
      createdBy: adminUser,
      updatedBy: adminUser,
    };
  }
}
