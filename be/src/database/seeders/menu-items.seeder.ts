import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { MenuItem } from '../../store-menus/entities/menu-item.entity';
import { StoreMenu } from '../../store-menus/entities/store-menu.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { PRODUCT_VARIANTS_FIXTURE } from './fixtures/product-variants.fixture';
import {
  DEFAULT_STORE_MENU_NAME,
  PRODUCT_GROUP_TO_MENU_CATEGORY,
} from './fixtures/menu-items.fixture';

const PRICE_MIN = 100;
const PRICE_MAX = 150;

/**
 * Seeder: MenuItemsSeeder
 * Requires StoreMenusSeeder and ProductVariantsSeeder to run first.
 * Adds all product variants to the DEFAULT store menu with default price and category from product group.
 */
export class MenuItemsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const storeMenuRepo = dataSource.getRepository(StoreMenu);
    const variantRepo = dataSource.getRepository(ProductVariant);
    const menuItemRepo = dataSource.getRepository(MenuItem);
    const defaultMenu = await storeMenuRepo.findOne({
      where: { name: DEFAULT_STORE_MENU_NAME },
    });
    if (!defaultMenu) {
      throw new Error(
        `Store menu "${DEFAULT_STORE_MENU_NAME}" not found. Run StoreMenusSeeder first.`,
      );
    }
    const variantKeySet = new Set(
      PRODUCT_VARIANTS_FIXTURE.flatMap((f) => f.variantNames.map((vn) => `${f.productName}:${vn}`)),
    );
    const variants = await variantRepo.find({
      relations: { product: { productGroup: true } },
    });
    const relevantVariants = variants.filter((v) =>
      variantKeySet.has(`${v.product.name}:${v.name}`),
    );
    if (relevantVariants.length === 0) {
      console.log('No product variants found for menu items, skip');
      return;
    }
    const existingItems = await menuItemRepo.find({
      where: { storeMenu: { id: defaultMenu.id } },
      relations: { productVariant: true },
      select: { id: true, productVariant: { id: true } },
    });
    const existingVariantIds = new Set(
      existingItems.filter((i) => i.productVariant != null).map((i) => i.productVariant!.id),
    );
    const toInsertVariants = relevantVariants.filter((v) => !existingVariantIds.has(v.id));
    if (toInsertVariants.length === 0) {
      console.log('Menu items already seeded, skip');
      return;
    }
    const data = await this.getData(adminUser, defaultMenu, toInsertVariants);
    const persistedData = await menuItemRepo.save(data);
    await menuItemRepo.save(persistedData);
    console.log(`${persistedData.length} menu items seeded`);
  }

  private getData(
    adminUser: Awaited<ReturnType<SeederHelper['getAdminUser']>>,
    storeMenu: StoreMenu,
    variants: ProductVariant[],
  ): Promise<Partial<MenuItem>[]> {
    const base = {
      storeMenu,
      isAvailable: true,
      createdBy: adminUser,
      updatedBy: adminUser,
    };
    return Promise.resolve(
      variants.map((variant, index) => {
        const groupName = variant.product.productGroup.name;
        const category = PRODUCT_GROUP_TO_MENU_CATEGORY[groupName] ?? groupName;
        return {
          ...base,
          productVariant: variant,
          displayPrice: (PRICE_MIN + (index % (PRICE_MAX - PRICE_MIN + 1))).toFixed(2),
          category,
          displayOrder: index,
        };
      }),
    );
  }
}
