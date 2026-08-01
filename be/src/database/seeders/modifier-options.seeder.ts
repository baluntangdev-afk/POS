import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { MODIFIER_OPTIONS_FIXTURE } from './fixtures/modifier-options.fixture';

export class ModifierOptionsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const modifierGroupRepo = dataSource.getRepository(ModifierGroup);
    const modifierOptionRepo = dataSource.getRepository(ModifierOption);

    const groupNames = [...new Set(MODIFIER_OPTIONS_FIXTURE.map((g) => g.modifierGroupName))];
    const modifierGroups = await modifierGroupRepo.find({ where: { name: In(groupNames) } });
    const groupByName = new Map(modifierGroups.map((g) => [g.name, g]));

    const missingGroups = groupNames.filter((n) => !groupByName.has(n));
    if (missingGroups.length > 0) {
      throw new Error(
        `Modifier options fixture references missing groups: ${missingGroups.join(', ')}. Run ModifierGroupsSeeder first.`,
      );
    }

    const existingOptions = await modifierOptionRepo.find({ relations: { modifierGroup: true } });
    const existingByKey = new Map(
      existingOptions.map((o) => [`${o.modifierGroup.id}:${o.name}`, o]),
    );

    const toInsert: Partial<ModifierOption>[] = [];
    const toUpdate: ModifierOption[] = [];

    for (const groupFixture of MODIFIER_OPTIONS_FIXTURE) {
      const modifierGroup = groupByName.get(groupFixture.modifierGroupName)!;

      for (const opt of groupFixture.options) {
        const key = `${modifierGroup.id}:${opt.name}`;
        const existing = existingByKey.get(key);

        if (existing) {
          existing.priceAddOn = opt.priceAddOn;
          existing.isAvailable = opt.isAvailable;
          existing.sortOrder = opt.sortOrder;
          existing.updatedBy = adminUser;
          toUpdate.push(existing);
        } else {
          toInsert.push({
            modifierGroup,
            name: opt.name,
            priceAddOn: opt.priceAddOn,
            isAvailable: opt.isAvailable,
            sortOrder: opt.sortOrder,
            imageUrl: null,
            createdBy: adminUser,
            updatedBy: adminUser,
          });
        }
      }
    }

    if (toInsert.length > 0) await modifierOptionRepo.save(toInsert);
    if (toUpdate.length > 0) await modifierOptionRepo.save(toUpdate);

    console.log(
      `Modifier options: ${toInsert.length} inserted, ${toUpdate.length} updated`,
    );
  }
}
