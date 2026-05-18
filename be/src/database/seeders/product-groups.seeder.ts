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

/**
 * Seeder: ProductGroupsSeeder
 */
export class ProductGroupsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const data = this.getData(adminUser);
    const repo = dataSource.getRepository(ProductGroup);

    const count = await repo.count();
    if (count > 0) {
      console.log('Product groups already seeded');
      return;
    }

    const persistedData = await repo.save(data);
    await repo.save(persistedData);
    console.log(`${persistedData.length} product groups seeded`);
  }

  private getData(adminUser: User): Partial<ProductGroup>[] {
    const base = { status: BaseStatus.ACTIVE, createdBy: adminUser, updatedBy: adminUser };
    return PRODUCT_GROUPS_FIXTURE.map((item) => ({
      ...base,
      name: item.name,
      description: item.description,
      imageUrl: getProductGroupImageBuffer(item),
    }));
  }
}
