import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { RecipeStatus } from '../../recipes/recipes.enum';
import { SeederHelper } from '../../utils/seeder.helper';
import { PRODUCT_VARIANTS_FIXTURE } from './fixtures/product-variants.fixture';

/** Default UOM code for recipe yield (e.g. serving). */
const DEFAULT_YIELD_UOM_CODE = 'SERV';

/**
 * Seeder: RecipesSeeder
 * Requires ProductVariantsSeeder and UomSeeder to run first.
 * Creates one recipe per product variant.
 */
export class RecipesSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const variantRepo = dataSource.getRepository(ProductVariant);
    const recipeRepo = dataSource.getRepository(Recipe);
    const uomRepo = dataSource.getRepository(Uom);

    const variants = await variantRepo.find({ relations: { product: true } });
    const variantKey = (v: ProductVariant) => `${v.product.name}:${v.name}`;
    const variantsFromFixture = new Set(
      PRODUCT_VARIANTS_FIXTURE.flatMap((f) => f.variants.map((v) => `${f.productName}:${v.name}`)),
    );
    // A live variant can still belong to a soft-deleted product, which loads as null.
    const relevantVariants = variants.filter(
      (v) => v.product != null && variantsFromFixture.has(variantKey(v)),
    );

    // Read the raw FK (including soft-deleted recipes/variants): joining the relation
    // yields null for soft-deleted variants, and product_variant_id is unique anyway.
    const existingRecipes = await recipeRepo
      .createQueryBuilder('r')
      .withDeleted()
      .select('r.product_variant_id', 'variantId')
      .getRawMany<{ variantId: number }>();
    const existingVariantIds = new Set(existingRecipes.map((r) => r.variantId));
    const toInsertVariants = relevantVariants.filter((v) => !existingVariantIds.has(v.id));
    if (toInsertVariants.length === 0) {
      console.log('Recipes already seeded, skip');
      return;
    }

    const yieldUnit = await uomRepo.findOne({ where: { code: DEFAULT_YIELD_UOM_CODE } });
    if (!yieldUnit) {
      throw new Error(`Yield UOM not found: ${DEFAULT_YIELD_UOM_CODE}. Run UomSeeder first.`);
    }

    const data = await this.getData(adminUser, toInsertVariants, yieldUnit);
    const persistedData = await recipeRepo.save(data);
    await recipeRepo.save(persistedData);
    console.log(`${persistedData.length} recipes seeded`);
  }

  private getData(
    adminUser: Awaited<ReturnType<SeederHelper['getAdminUser']>>,
    variants: ProductVariant[],
    yieldUnit: Uom,
  ): Partial<Recipe>[] {
    const base = {
      yieldUnit,
      status: RecipeStatus.ACTIVE,
      createdBy: adminUser,
      updatedBy: adminUser,
    };

    return variants.map((v) => ({
      ...base,
      productVariant: v,
      name: `${v.product.name} - ${v.name}`,
      yieldQty: '5',
    }));
  }
}
