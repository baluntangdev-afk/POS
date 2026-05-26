import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Product } from '../../products/entities/product.entity';
import { ProductGroup } from '../../product-groups/entities/product-group.entity';
import { ProductStatus } from '../../products/products.enum';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { PRODUCTS_SEEDER_FIXTURE } from './fixtures/product.fixture';

export class ProductsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const productGroupRepo = dataSource.getRepository(ProductGroup);
    const productRepo = dataSource.getRepository(Product);

    const groupNames = [...new Set(PRODUCTS_SEEDER_FIXTURE.map((f) => f.groupName))];
    const productGroups = await productGroupRepo.find({ where: { name: In(groupNames) } });
    const productGroupByName = new Map(productGroups.map((g) => [g.name, g]));

    const existingProducts = await productRepo.find({
      withDeleted: true,
      relations: { productGroup: true },
    });
    const existingByName = new Map(existingProducts.map((p) => [p.name, p]));

    const toInsert: Partial<Product>[] = [];
    const toUpdate: Product[] = [];
    const fixtureNames = new Set(PRODUCTS_SEEDER_FIXTURE.map((f) => f.name));
    const fixtureGroupNames = new Set<string>(groupNames);

    for (const item of PRODUCTS_SEEDER_FIXTURE) {
      const productGroup = productGroupByName.get(item.groupName);
      if (!productGroup) {
        throw new Error(`Product fixture references missing group: ${item.groupName}`);
      }

      const existing = existingByName.get(item.name);
      if (existing) {
        existing.productGroup = productGroup;
        existing.description = item.description;
        existing.price = item.price;
        existing.isAvailable = true;
        existing.sortOrder = item.sortOrder;
        existing.status = ProductStatus.ACTIVE;
        existing.deletedAt = null;
        existing.updatedBy = adminUser;
        toUpdate.push(existing);
      } else {
        toInsert.push(this.buildProduct(adminUser, productGroup, item));
      }
    }

    // Soft-delete products inside fixture groups that are no longer in the fixture
    for (const [name, product] of existingByName) {
      if (!fixtureNames.has(name) && !product.deletedAt) {
        const groupName = product.productGroup?.name;
        if (groupName && fixtureGroupNames.has(groupName)) {
          product.deletedAt = new Date();
          product.deletedBy = adminUser;
          toUpdate.push(product);
        }
      }
    }

    if (toInsert.length > 0) await productRepo.save(toInsert);
    if (toUpdate.length > 0) await productRepo.save(toUpdate);

    console.log(`Products: ${toInsert.length} inserted, ${toUpdate.length} updated/soft-deleted`);
  }

  private buildProduct(
    adminUser: User,
    productGroup: ProductGroup,
    item: (typeof PRODUCTS_SEEDER_FIXTURE)[number],
  ): Partial<Product> {
    return {
      productGroup,
      name: item.name,
      description: item.description,
      price: item.price,
      isAvailable: true,
      sortOrder: item.sortOrder,
      imageUrl: null,
      status: ProductStatus.ACTIVE,
      createdBy: adminUser,
      updatedBy: adminUser,
    };
  }
}
