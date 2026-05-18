import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { RecipeItem } from '../../recipes/entities/recipe-item.entity';
import { Material } from '../../materials/entities/material.entity';
import { User } from '../../users/entities/user.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import {
  MODIFIER_OPTIONS_FIXTURE,
  ModifierOptionFixtureItem,
} from './fixtures/modifier-options.fixture';

/**
 * Seeder: ModifierOptionsSeeder
 * Requires ModifierGroupsSeeder, RecipeItemsSeeder and MaterialsSeeder to run first.
 */
export class ModifierOptionsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const modifierGroupRepo = dataSource.getRepository(ModifierGroup);
    const recipeItemRepo = dataSource.getRepository(RecipeItem);
    const materialRepo = dataSource.getRepository(Material);
    const modifierOptionRepo = dataSource.getRepository(ModifierOption);
    const groupNames = [...new Set(MODIFIER_OPTIONS_FIXTURE.map((g) => g.modifierGroupName))];
    const modifierGroups = await modifierGroupRepo.find({
      where: { name: In(groupNames) },
    });
    const groupByName = new Map(modifierGroups.map((g) => [g.name, g]));
    const missingGroups = groupNames.filter((n) => !groupByName.has(n));
    if (missingGroups.length > 0) {
      throw new Error(
        `Modifier options fixture references missing modifier groups: ${missingGroups.join(', ')}. Run ModifierGroupsSeeder first.`,
      );
    }
    const recipeItems = await recipeItemRepo.find({
      relations: { recipe: { productVariant: { product: true } }, material: true },
    });
    const recipeItemKey = (ri: RecipeItem) =>
      `${ri.recipe.productVariant.product.name}:${ri.recipe.productVariant.name}:${ri.material.materialName}`;
    const recipeItemByKey = new Map(recipeItems.map((ri) => [recipeItemKey(ri), ri]));
    const materialNames = [
      ...new Set(
        MODIFIER_OPTIONS_FIXTURE.flatMap((g) =>
          g.options
            .filter(
              (o): o is ModifierOptionFixtureItem & { type: 'material'; materialName: string } =>
                o.type === 'material',
            )
            .map((o) => o.materialName),
        ),
      ),
    ];
    const materials =
      materialNames.length > 0
        ? await materialRepo.find({ where: { materialName: In(materialNames) } })
        : [];
    const materialByName = new Map(materials.map((m) => [m.materialName, m]));
    const existingOptions = await modifierOptionRepo.find({
      relations: { modifierGroup: true },
    });
    const existingByKey = new Map(
      existingOptions.map((o) => [`${o.modifierGroup.id}:${o.name}`, o]),
    );
    const toInsert: Partial<ModifierOption>[] = [];
    const insertFksByKey = new Map<
      string,
      { materialId: number | null; recipeItemId: number | null }
    >();
    const toUpdate: Array<{
      entity: ModifierOption;
      materialId: number | null;
      recipeItemId: number | null;
      priceAddOn: string;
      updatedBy: User;
    }> = [];
    for (const groupFixture of MODIFIER_OPTIONS_FIXTURE) {
      const modifierGroup = groupByName.get(groupFixture.modifierGroupName)!;
      for (const opt of groupFixture.options) {
        const key = `${modifierGroup.id}:${opt.name}`;
        let recipeItem: RecipeItem | null = null;
        let material: Material | null = null;
        if (opt.type === 'recipeItem') {
          const refKey = `${opt.productName}:${opt.variantName}:${opt.materialName}`;
          recipeItem = recipeItemByKey.get(refKey) ?? null;
          if (!recipeItem) {
            throw new Error(
              `Modifier option "${opt.name}": recipe item not found (${refKey}). Run RecipeItemsSeeder first.`,
            );
          }
        } else if (opt.type === 'material') {
          material = materialByName.get(opt.materialName) ?? null;
          if (!material) {
            throw new Error(
              `Modifier option "${opt.name}": material "${opt.materialName}" not found. Run MaterialsSeeder first.`,
            );
          }
        }
        const materialId = material?.id ?? null;
        const recipeItemId = recipeItem?.id ?? null;
        const priceAddOn = 'priceAddOn' in opt && opt.priceAddOn != null ? opt.priceAddOn : '0';
        const existing = existingByKey.get(key);
        if (existing) {
          toUpdate.push({
            entity: existing,
            materialId,
            recipeItemId,
            priceAddOn,
            updatedBy: adminUser,
          });
        } else {
          toInsert.push({
            modifierGroup,
            name: opt.name,
            priceAddOn,
            imageUrl: null,
            createdBy: adminUser,
            updatedBy: adminUser,
          });
          insertFksByKey.set(key, { materialId, recipeItemId });
        }
      }
    }
    if (toUpdate.length > 0) {
      for (const { entity, materialId, recipeItemId, priceAddOn, updatedBy } of toUpdate) {
        await dataSource.query(
          `UPDATE modifier_options SET material_id = $1, recipe_item_id = $2, price_add_on = $3, updated_by = $4 WHERE id = $5`,
          [materialId, recipeItemId, priceAddOn, updatedBy.id, entity.id],
        );
      }
      console.log(`${toUpdate.length} modifier options updated`);
    }
    if (toInsert.length > 0) {
      const saved = await modifierOptionRepo.save(toInsert);
      const ids = saved.map((row) => row.id);
      const withGroup = await modifierOptionRepo.find({
        where: { id: In(ids) },
        relations: { modifierGroup: true },
        select: { id: true, name: true, modifierGroup: { id: true } },
      });
      for (const row of withGroup) {
        const key = `${row.modifierGroup.id}:${row.name}`;
        const fks = insertFksByKey.get(key);
        if (fks) {
          await dataSource.query(
            `UPDATE modifier_options SET material_id = $1, recipe_item_id = $2 WHERE id = $3`,
            [fks.materialId ?? null, fks.recipeItemId ?? null, row.id],
          );
        }
      }
      console.log(`${toInsert.length} modifier options seeded`);
    }
    if (toInsert.length === 0 && toUpdate.length === 0) {
      console.log('Modifier options already in sync, skip');
    }
  }
}
