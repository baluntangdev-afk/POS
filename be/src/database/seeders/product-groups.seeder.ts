import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ProductGroup } from '../../product-groups/entities/product-group.entity';
import { BaseStatus } from '../../utils/shared-enums';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import {
  PRODUCT_GROUPS_FIXTURE,
  getProductGroupImageBuffer,
} from './fixtures/product-groups.fixture';

export class ProductGroupsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const repo = dataSource.getRepository(ProductGroup);

    const existingGroups = await repo.find({ withDeleted: true });
    const existingByName = new Map(existingGroups.map((g) => [g.name, g]));

    const toInsert: Partial<ProductGroup>[] = [];
    const toUpdate: ProductGroup[] = [];
    const fixtureNames = new Set(PRODUCT_GROUPS_FIXTURE.map((f) => f.name));

    for (const item of PRODUCT_GROUPS_FIXTURE) {
      const existing = existingByName.get(item.name);
      if (existing) {
        existing.description = item.description;
        existing.imageUrl = getProductGroupImageBuffer(item);
        existing.status = BaseStatus.ACTIVE;
        existing.deletedAt = null;
        existing.updatedBy = adminUser;
        toUpdate.push(existing);
      } else {
        toInsert.push(this.buildGroup(adminUser, item));
      }
    }

    // Soft-delete groups not in fixture (they are old/obsolete catalog groups)
    for (const [name, group] of existingByName) {
      if (!fixtureNames.has(name) && !group.deletedAt) {
        group.deletedAt = new Date();
        group.deletedBy = adminUser;
        toUpdate.push(group);
      }
    }

    if (toInsert.length > 0) await repo.save(toInsert);
    if (toUpdate.length > 0) await repo.save(toUpdate);

    console.log(
      `Product groups: ${toInsert.length} inserted, ${toUpdate.length} updated/soft-deleted`,
    );
  }

  private buildGroup(adminUser: User, item: (typeof PRODUCT_GROUPS_FIXTURE)[number]): Partial<ProductGroup> {
    return {
      name: item.name,
      description: item.description,
      imageUrl: getProductGroupImageBuffer(item),
      status: BaseStatus.ACTIVE,
      createdBy: adminUser,
      updatedBy: adminUser,
    };
  }
}
