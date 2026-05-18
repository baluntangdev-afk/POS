import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Product } from '../../products/entities/product.entity';
import { ProductGroup } from '../../product-groups/entities/product-group.entity';
import { ProductStatus } from '../../products/products.enum';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { PRODUCTS_SEEDER_FIXTURE, getProductImageBuffer } from './fixtures/product.fixture';

/**
 * Seeder: ProductsSeeder
 * Requires ProductGroupsSeeder to run first.
 * Beverage images are randomly selected from assets/beverage-products; others use fixed filenames per group.
 */
export class ProductsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const productGroupRepo = dataSource.getRepository(ProductGroup);
    const productRepo = dataSource.getRepository(Product);

    const groupNames = [...new Set(PRODUCTS_SEEDER_FIXTURE.map((f) => f.groupName))];
    const productGroups = await productGroupRepo.find({
      where: { name: In(groupNames) },
    });

    const productGroupByName = new Map(productGroups.map((g) => [g.name, g]));
    const existingProducts = await productRepo.createQueryBuilder('p').select('p.name').getMany();
    const existingNames = new Set(existingProducts.map((r) => r.name));

    const toInsertItems = PRODUCTS_SEEDER_FIXTURE.filter((item) => !existingNames.has(item.name));
    if (toInsertItems.length === 0) {
      console.log('Products already seeded, skip');
      return;
    }

    const data = this.getData(adminUser, toInsertItems, productGroupByName);
    const persistedData = await productRepo.save(data);
    await productRepo.save(persistedData);
    console.log(`${persistedData.length} products seeded`);
  }

  private getData(
    adminUser: User,
    items: typeof PRODUCTS_SEEDER_FIXTURE,
    productGroupByName: Map<string, ProductGroup>,
  ): Partial<Product>[] {
    const base = {
      status: ProductStatus.ACTIVE,
      createdBy: adminUser,
      updatedBy: adminUser,
    };

    return items.map((item) => {
      const productGroup = productGroupByName.get(item.groupName);

      if (!productGroup) {
        throw new Error(`Product fixture references missing group: ${item.groupName}`);
      }

      return {
        ...base,
        productGroup,
        name: item.name,
        description: item.description,
        imageUrl: getProductImageBuffer(item),
      };
    });
  }
}
