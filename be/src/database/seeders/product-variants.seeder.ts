import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { Product } from '../../products/entities/product.entity';
import { ProductVariantStatus } from '../../products/products.enum';
import { SeederHelper } from '../../utils/seeder.helper';
import { PRODUCT_VARIANTS_FIXTURE } from './fixtures/product-variants.fixture';

/**
 * Seeder: ProductVariantsSeeder
 * Requires ProductsSeeder to run first.
 */
export class ProductVariantsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const productRepo = dataSource.getRepository(Product);
    const variantRepo = dataSource.getRepository(ProductVariant);

    const productNames = [...new Set(PRODUCT_VARIANTS_FIXTURE.map((f) => f.productName))];
    const products = await productRepo.find({ where: { name: In(productNames) } });
    const productByName = new Map(products.map((p) => [p.name, p]));

    const existingVariants = await variantRepo.find({
      relations: { product: true },
      select: { id: true, name: true, product: { id: true } },
    });
    const existingKeySet = new Set(existingVariants.map((v) => `${v.product.id}:${v.name}`));

    const toInsert: Partial<ProductVariant>[] = [];
    for (const item of PRODUCT_VARIANTS_FIXTURE) {
      const product = productByName.get(item.productName);
      if (!product) {
        throw new Error(`Product variant fixture references missing product: ${item.productName}`);
      }

      const productId = product.id;
      item.variants.forEach(({ name, price }, index) => {
        const key = `${productId}:${name}`;

        if (existingKeySet.has(key)) {
          return;
        }

        existingKeySet.add(key);
        toInsert.push({
          product,
          name,
          price,
          status: ProductVariantStatus.ACTIVE,
          isDefault: index === 0,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      });
    }

    if (toInsert.length === 0) {
      console.log('Product variants already seeded, skip');
      return;
    }

    const persistedData = await variantRepo.save(toInsert);
    await variantRepo.save(persistedData);
    console.log(`${persistedData.length} product variants seeded`);
  }
}
