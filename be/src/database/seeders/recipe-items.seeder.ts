import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { RecipeItem } from '../../recipes/entities/recipe-item.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { Material } from '../../materials/entities/material.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { PRODUCT_VARIANTS_FIXTURE } from './fixtures/product-variants.fixture';
import { RECIPE_ITEMS_FIXTURE } from './fixtures/recipe-items.fixture';

const ALL_MATERIAL_NAMES = [
  ...new Set(
    RECIPE_ITEMS_FIXTURE.flatMap((f) => [...f.materialNames, ...(f.extraMaterialNames ?? [])]),
  ),
];

/**
 * Seeder: RecipeItemsSeeder
 * Requires RecipesSeeder and MaterialsSeeder to run first.
 * Creates recipe items per recipe using only the materials suited for that product.
 */
export class RecipeItemsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const recipeRepo = dataSource.getRepository(Recipe);
    const materialRepo = dataSource.getRepository(Material);
    const recipeItemRepo = dataSource.getRepository(RecipeItem);

    const variantKeySet = new Set(
      PRODUCT_VARIANTS_FIXTURE.flatMap((f) => f.variants.map((v) => `${f.productName}:${v.name}`)),
    );

    const recipes = await recipeRepo.find({
      relations: { productVariant: { product: true } },
    });
    const relevantRecipes = recipes.filter((r) =>
      variantKeySet.has(`${r.productVariant.product.name}:${r.productVariant.name}`),
    );

    if (relevantRecipes.length === 0) {
      console.log('No recipes found for product variants, skip');
      return;
    }

    const materials = await materialRepo.find({
      where: { materialName: In(ALL_MATERIAL_NAMES) },
      relations: { standardBaseUnit: true },
    });
    const materialByName = new Map(materials.map((m) => [m.materialName, m]));
    const missing = ALL_MATERIAL_NAMES.filter((n) => !materialByName.has(n));

    if (missing.length > 0) {
      throw new Error(
        `Recipe items fixture references missing materials: ${missing.join(', ')}. Run MaterialsSeeder first.`,
      );
    }

    const existingItems = await recipeItemRepo.find({
      relations: { recipe: true, material: true },
      select: { id: true, recipe: { id: true }, material: { id: true } },
    });
    const fixtureByProduct = new Map(RECIPE_ITEMS_FIXTURE.map((f) => [f.productName, f]));
    const existingItemsByKey = new Map(
      existingItems.map((i) => [`${i.recipe!.id}:${i.material!.id}`, i]),
    );

    const toUpsert: Partial<RecipeItem>[] = [];
    for (const recipe of relevantRecipes) {
      const productName = recipe.productVariant.product.name;
      const fixture = fixtureByProduct.get(productName);
      if (!fixture) {
        continue;
      }

      const baseMaterials = fixture.materialNames.map((name) => ({
        materialName: name,
        extra: false,
      }));
      const extraMaterials = (fixture.extraMaterialNames ?? []).map((name) => ({
        materialName: name,
        extra: true,
      }));
      const allMaterials = [...baseMaterials, ...extraMaterials];

      for (const { materialName, extra } of allMaterials) {
        const material = materialByName.get(materialName)!;
        const key = `${recipe.id}:${material.id}`;
        const existing = existingItemsByKey.get(key);

        if (existing) {
          toUpsert.push({
            ...existing,
            extra,
            updatedBy: adminUser,
          });
        } else {
          toUpsert.push({
            recipe,
            material,
            quantity: '',
            unit: material.standardBaseUnit,
            extra,
            createdBy: adminUser,
            updatedBy: adminUser,
          });
        }
      }
    }

    if (toUpsert.length === 0) {
      console.log('No recipe items to upsert, skip');
      return;
    }

    const data = this.fillQuantities(toUpsert);
    await recipeItemRepo.save(data);
    const newCount = data.filter((d) => d.id == null).length;
    const updatedCount = data.length - newCount;
    console.log(`${data.length} recipe items upserted (${newCount} new, ${updatedCount} updated)`);
  }

  private fillQuantities(items: Partial<RecipeItem>[]): Partial<RecipeItem>[] {
    return items.map((item) => ({
      ...item,
      quantity: '1',
    }));
  }
}
