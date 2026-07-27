import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import { ProductGroup } from '../../../product-groups/entities/product-group.entity';
import { Product } from '../../../products/entities/product.entity';
import { ProductVariant } from '../../../products/entities/product-variant.entity';
import { ProductStatus, ProductVariantStatus } from '../../../products/products.enum';
import { Recipe } from '../../../recipes/entities/recipe.entity';
import { RecipeStatus } from '../../../recipes/recipes.enum';
import { Uom } from '../../../uom/entities/uom.entity';
import { BaseStatus } from '../../../utils/shared-enums';
import { SeederHelper } from '../../../utils/seeder.helper';

/** Yield UOM code every CSV variant's recipe is created with (seeded by UomSeeder). */
const DEFAULT_YIELD_UOM_CODE = 'SERV';
/** Default yield quantity for an auto-created recipe — matches the legacy RecipesSeeder. */
const DEFAULT_RECIPE_YIELD_QTY = '5';
/**
 * Variant name given to single-price products (CSV rows with a blank Variant
 * Name). The order flow is variant-based, so every product needs at least one
 * variant to be orderable.
 */
const DEFAULT_VARIANT_NAME = 'Regular';

export interface ProductsCsvSeedSummary {
  categoriesInserted: number;
  categoriesUpdated: number;
  categoriesDeleted: number;
  productsInserted: number;
  productsUpdated: number;
  productsDeleted: number;
  variantsInserted: number;
  variantsUpdated: number;
  variantsDeleted: number;
}

interface CategoryData {
  name: string;
  description: string;
}

interface VariantData {
  name: string;
  price: number;
}

interface ProductData {
  name: string;
  description: string;
  /** Kept as a string — Product.price is a decimal column typed as string. */
  basePrice: string;
  categoryName: string;
  variants: VariantData[];
  sortOrder: number;
  /** Optional product image URL from the CSV; null when the column is absent or blank. */
  imageUrl: string | null;
}

/**
 * Collapses the flat CSV rows into unique categories and products. Multiple rows
 * sharing a Product Name accumulate into one product with many variants. A
 * product whose rows all have a blank Variant Name (single-price product) is
 * given one default "Regular" variant priced at its base price, so it is still
 * orderable through the variant-based order flow.
 */
export function groupRows(rows: string[][]): {
  categories: CategoryData[];
  products: ProductData[];
} {
  const categoryMap = new Map<string, CategoryData>();
  const productMap = new Map<string, ProductData>();
  let productOrder = 0;

  for (const row of rows) {
    const [
      category,
      categoryDesc,
      productName,
      productDesc,
      basePrice,
      variantName,
      variantPrice,
      imageUrl,
    ] = row;

    if (!categoryMap.has(category)) {
      categoryMap.set(category, { name: category, description: categoryDesc ?? '' });
    }

    const productKey = `${category}::${productName}`;
    if (!productMap.has(productKey)) {
      productMap.set(productKey, {
        name: productName,
        description: productDesc ?? '',
        basePrice: (basePrice ?? '').trim(),
        categoryName: category,
        variants: [],
        sortOrder: productOrder++,
        imageUrl: imageUrl?.trim() ? imageUrl.trim() : null,
      });
    } else {
      // First non-empty image URL across the product's rows wins, so a product
      // spread over many variant rows can carry its image on any single row.
      const product = productMap.get(productKey)!;
      if (!product.imageUrl && imageUrl?.trim()) {
        product.imageUrl = imageUrl.trim();
      }
    }

    if (variantName?.trim()) {
      productMap.get(productKey)!.variants.push({
        name: variantName.trim(),
        price: parseFloat(variantPrice),
      });
    }
  }

  // Single-price products (no variant rows) get a default variant from their
  // base price so they remain orderable. Base price is validated as a number.
  for (const product of productMap.values()) {
    if (product.variants.length === 0) {
      product.variants.push({
        name: DEFAULT_VARIANT_NAME,
        price: parseFloat(product.basePrice),
      });
    }
  }

  return {
    categories: [...categoryMap.values()],
    products: [...productMap.values()],
  };
}

/**
 * Identity of a product within the catalog: category + name. Product names are
 * unique PER CATEGORY (group), not globally, so every lookup/upsert must key on
 * this pair — keying by name alone collapses same-named products from different
 * categories (e.g. "Avocado Premium" in Smoothies vs Salads) into one.
 */
function productKey(categoryName: string, productName: string): string {
  return `${categoryName}::${productName}`;
}

/** Existing categories absent from the imported CSV and not already soft-deleted. */
export function categoriesToSoftDelete(
  existingGroups: ProductGroup[],
  csvCategoryNames: Set<string>,
): ProductGroup[] {
  return existingGroups.filter((group) => !csvCategoryNames.has(group.name) && !group.deletedAt);
}

/** Existing products (with their category relation loaded) absent from the imported CSV. */
export function productsToSoftDelete(
  existingProducts: Product[],
  csvProductKeys: Set<string>,
): Product[] {
  return existingProducts.filter((product) => {
    if (!product.productGroup) return false;
    const key = productKey(product.productGroup.name, product.name);
    return !csvProductKeys.has(key) && !product.deletedAt;
  });
}

/** Existing variants (with their product relation loaded) absent from the imported CSV. */
export function variantsToSoftDelete(
  existingVariants: ProductVariant[],
  csvVariantKeys: Set<string>,
): ProductVariant[] {
  return existingVariants.filter((variant) => {
    const key = `${variant.product.id}:${variant.name}`;
    return !csvVariantKeys.has(key) && !variant.deletedAt;
  });
}

/**
 * Seeds categories, products, and variants from validated CSV rows in four
 * upsert passes. By default (`authoritative: true`) the CSV is treated as the
 * full catalog: any category, product, or variant NOT present in the CSV is
 * soft-deleted, guaranteeing the store's catalog matches the CSV exactly. This
 * is used by the CLI/recovery path. Passing `authoritative: false` (used by the
 * in-app import endpoint) skips all soft-deletes — rows are only upserted, so
 * importing a partial catalog never removes products added elsewhere.
 *
 * Pass 4 creates one ACTIVE recipe per variant. A recipe is mandatory for a
 * variant to be orderable — `SalesOrderItemBuildService.enrichProduct` throws
 * "Recipe not found for product variant" otherwise. The catalog is no longer
 * seeded from local fixtures (the legacy RecipesSeeder used to create these),
 * so the CSV seeder must produce a fully orderable catalog itself.
 *
 * Idempotent — re-running upserts by category+name (undeleting matches), re-applies the
 * soft-deletes when authoritative, and creates recipes only for variants that
 * lack one, so it is safe to run on every install and recovery.
 */
export class ProductsCsvSeeder {
  async run(
    dataSource: DataSource,
    rows: string[][],
    options?: { authoritative?: boolean },
  ): Promise<ProductsCsvSeedSummary> {
    const authoritative = options?.authoritative ?? true;
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const groupRepo = dataSource.getRepository(ProductGroup);
    const productRepo = dataSource.getRepository(Product);
    const variantRepo = dataSource.getRepository(ProductVariant);

    const { categories, products } = groupRows(rows);
    const csvCategoryNames = new Set(categories.map((c) => c.name));
    const csvProductKeys = new Set(products.map((p) => productKey(p.categoryName, p.name)));

    // ── Pass 1: Product Groups (categories) ──────────────────────────────
    const existingGroups = await groupRepo.find({ withDeleted: true });
    const groupByName = new Map(existingGroups.map((g) => [g.name, g]));
    const groupsToInsert: Partial<ProductGroup>[] = [];
    const groupsToUpdate: ProductGroup[] = [];

    for (const cat of categories) {
      const existing = groupByName.get(cat.name);
      if (existing) {
        existing.description = cat.description;
        existing.status = BaseStatus.ACTIVE;
        existing.deletedAt = null;
        existing.deletedBy = null;
        existing.updatedBy = adminUser;
        groupsToUpdate.push(existing);
      } else {
        groupsToInsert.push({
          name: cat.name,
          description: cat.description,
          imageUrl: null,
          status: BaseStatus.ACTIVE,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      }
    }

    // Soft-delete categories not present in the CSV (only when authoritative)
    let categoriesDeleted = 0;
    if (authoritative) {
      for (const group of categoriesToSoftDelete(existingGroups, csvCategoryNames)) {
        group.deletedAt = new Date();
        group.deletedBy = adminUser;
        groupsToUpdate.push(group);
        categoriesDeleted++;
      }
    }

    if (groupsToInsert.length > 0) await groupRepo.save(groupsToInsert);
    if (groupsToUpdate.length > 0) await groupRepo.save(groupsToUpdate);
    console.log(
      `  Categories: ${groupsToInsert.length} inserted, ${groupsToUpdate.length - categoriesDeleted} updated, ${categoriesDeleted} soft-deleted`,
    );

    // Reload groups with IDs for foreign keys
    const allGroups = await groupRepo.find({ where: { name: In(categories.map((c) => c.name)) } });
    const groupIdByName = new Map(allGroups.map((g) => [g.name, g]));

    // ── Pass 2: Products ──────────────────────────────────────────────────
    const existingProducts = await productRepo.find({
      withDeleted: true,
      relations: { productGroup: true },
    });
    const productByKey = new Map(
      existingProducts
        .filter((p) => p.productGroup)
        .map((p) => [productKey(p.productGroup.name, p.name), p]),
    );
    const productsToInsert: Partial<Product>[] = [];
    const productsToUpdate: Product[] = [];

    for (const prod of products) {
      const productGroup = groupIdByName.get(prod.categoryName);
      if (!productGroup) continue;

      const existing = productByKey.get(productKey(prod.categoryName, prod.name));
      if (existing) {
        existing.productGroup = productGroup;
        existing.description = prod.description;
        existing.price = prod.basePrice;
        existing.isAvailable = true;
        existing.sortOrder = prod.sortOrder;
        // Only overwrite the image when the CSV provides one, so re-importing a
        // file without the (optional) image column does not wipe existing images.
        if (prod.imageUrl) existing.imageUrl = prod.imageUrl;
        existing.status = ProductStatus.ACTIVE;
        existing.deletedAt = null;
        existing.deletedBy = null;
        existing.updatedBy = adminUser;
        productsToUpdate.push(existing);
      } else {
        productsToInsert.push({
          productGroup,
          name: prod.name,
          description: prod.description,
          price: prod.basePrice,
          isAvailable: true,
          sortOrder: prod.sortOrder,
          imageUrl: prod.imageUrl,
          status: ProductStatus.ACTIVE,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      }
    }

    // Soft-delete products not present in the CSV (only when authoritative)
    let productsDeleted = 0;
    if (authoritative) {
      for (const product of productsToSoftDelete(existingProducts, csvProductKeys)) {
        product.deletedAt = new Date();
        product.deletedBy = adminUser;
        productsToUpdate.push(product);
        productsDeleted++;
      }
    }

    if (productsToInsert.length > 0) await productRepo.save(productsToInsert);
    if (productsToUpdate.length > 0) await productRepo.save(productsToUpdate);
    console.log(
      `  Products: ${productsToInsert.length} inserted, ${productsToUpdate.length - productsDeleted} updated, ${productsDeleted} soft-deleted`,
    );

    // Reload products with IDs for variant foreign keys. Keyed by category+name
    // because the same name can exist in two categories as distinct products.
    const allProducts = await productRepo.find({
      where: { name: In(products.map((p) => p.name)) },
      relations: { productGroup: true },
    });
    const productByKeyReloaded = new Map(
      allProducts
        .filter((p) => p.productGroup)
        .map((p) => [productKey(p.productGroup.name, p.name), p]),
    );

    // ── Pass 3: Product Variants ──────────────────────────────────────────
    const existingVariants = await variantRepo.find({
      withDeleted: true,
      relations: { product: true },
    });
    const existingVariantByKey = new Map(
      existingVariants.map((v) => [`${v.product.id}:${v.name}`, v]),
    );
    const csvVariantKeys = new Set<string>();
    const variantsToInsert: Partial<ProductVariant>[] = [];
    const variantsToUpdate: ProductVariant[] = [];

    for (const prod of products) {
      if (prod.variants.length === 0) continue;
      const product = productByKeyReloaded.get(productKey(prod.categoryName, prod.name));
      if (!product) continue;

      prod.variants.forEach((variant, index) => {
        const key = `${product.id}:${variant.name}`;
        csvVariantKeys.add(key);

        const existing = existingVariantByKey.get(key);
        if (existing) {
          existing.price = variant.price;
          existing.status = ProductVariantStatus.ACTIVE;
          existing.isDefault = index === 0;
          existing.deletedAt = null;
          existing.deletedBy = null;
          existing.updatedBy = adminUser;
          variantsToUpdate.push(existing);
        } else {
          variantsToInsert.push({
            product,
            name: variant.name,
            price: variant.price,
            status: ProductVariantStatus.ACTIVE,
            isDefault: index === 0,
            createdBy: adminUser,
            updatedBy: adminUser,
          });
        }
      });
    }

    // Soft-delete variants not present in the CSV (only when authoritative)
    let variantsDeleted = 0;
    if (authoritative) {
      for (const variant of variantsToSoftDelete(existingVariants, csvVariantKeys)) {
        variant.deletedAt = new Date();
        variant.deletedBy = adminUser;
        variantsToUpdate.push(variant);
        variantsDeleted++;
      }
    }

    if (variantsToInsert.length > 0) await variantRepo.save(variantsToInsert);
    if (variantsToUpdate.length > 0) await variantRepo.save(variantsToUpdate);
    console.log(
      `  Variants: ${variantsToInsert.length} inserted, ${variantsToUpdate.length - variantsDeleted} updated, ${variantsDeleted} soft-deleted`,
    );

    // ── Pass 4: Recipes (one per variant — required for orders) ───────────
    await this.ensureRecipesForVariants(dataSource, adminUser, csvProductKeys);

    return {
      categoriesInserted: groupsToInsert.length,
      categoriesUpdated: groupsToUpdate.length - categoriesDeleted,
      categoriesDeleted,
      productsInserted: productsToInsert.length,
      productsUpdated: productsToUpdate.length - productsDeleted,
      productsDeleted,
      variantsInserted: variantsToInsert.length,
      variantsUpdated: variantsToUpdate.length - variantsDeleted,
      variantsDeleted,
    };
  }

  /**
   * Ensures every active variant of a CSV product has an ACTIVE recipe, since a
   * variant cannot be ordered without one. Idempotent: only variants missing a
   * recipe get one created.
   */
  private async ensureRecipesForVariants(
    dataSource: DataSource,
    adminUser: Awaited<ReturnType<SeederHelper['getAdminUser']>>,
    csvProductKeys: Set<string>,
  ): Promise<void> {
    const variantRepo = dataSource.getRepository(ProductVariant);
    const recipeRepo = dataSource.getRepository(Recipe);
    const uomRepo = dataSource.getRepository(Uom);

    const yieldUnit = await uomRepo.findOne({ where: { code: DEFAULT_YIELD_UOM_CODE } });
    if (!yieldUnit) {
      throw new Error(
        `Yield UOM "${DEFAULT_YIELD_UOM_CODE}" not found. Run the standard seeder (--seed) first.`,
      );
    }

    const variants = await variantRepo.find({
      relations: { product: { productGroup: true } },
    });
    const relevantVariants = variants.filter(
      (v) =>
        v.product.productGroup &&
        csvProductKeys.has(productKey(v.product.productGroup.name, v.product.name)),
    );

    const existingRecipes = await recipeRepo.find({
      relations: { productVariant: true },
      select: { id: true, productVariant: { id: true } },
    });
    const variantIdsWithRecipe = new Set(existingRecipes.map((r) => r.productVariant.id));

    const recipesToInsert: Partial<Recipe>[] = relevantVariants
      .filter((v) => !variantIdsWithRecipe.has(v.id))
      .map((v) => ({
        productVariant: v,
        name: `${v.product.name} - ${v.name}`,
        yieldQty: DEFAULT_RECIPE_YIELD_QTY,
        yieldUnit,
        status: RecipeStatus.ACTIVE,
        createdBy: adminUser,
        updatedBy: adminUser,
      }));

    if (recipesToInsert.length > 0) await recipeRepo.save(recipesToInsert);
    console.log(`  Recipes: ${recipesToInsert.length} created`);
  }
}
