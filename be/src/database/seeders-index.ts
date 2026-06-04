import type { Seeder } from './seeders/seeder.interface';
import { CurrenciesSeeder } from './seeders/currencies.seeder';
import { DiscountsSeeder } from './seeders/discounts.seeder';
import { InventoryStocksSeeder } from './seeders/inventory-stocks.seeder';
import { InventoryTypesSeeder } from './seeders/inventory-types.seeder';
import { MaterialTypesSeeder } from './seeders/material-types.seeder';
import { MaterialsSeeder } from './seeders/materials.seeder';
import { MenuItemModifiersSeeder } from './seeders/menu-item-modifiers.seeder';
import { MenuItemsSeeder } from './seeders/menu-items.seeder';
import { ModifierGroupsSeeder } from './seeders/modifier-groups.seeder';
import { ModifierOptionsSeeder } from './seeders/modifier-options.seeder';
import { ProductGroupModifierGroupsSeeder } from './seeders/product-group-modifier-groups.seeder';
import { ProductGroupsSeeder } from './seeders/product-groups.seeder';
import { ProductModifierGroupsSeeder } from './seeders/product-modifier-groups.seeder';
import { ProductVariantsSeeder } from './seeders/product-variants.seeder';
import { ProductsSeeder } from './seeders/products.seeder';
import { RecipeItemsSeeder } from './seeders/recipe-items.seeder';
import { RecipesSeeder } from './seeders/recipes.seeder';
import { StoreMenusSeeder } from './seeders/store-menus.seeder';
import { TaxCategoriesSeeder } from './seeders/tax-categories.seeder';
import { UomSeeder } from './seeders/uom.seeder';
import { UsersSeeder } from './seeders/users.seeder';

/**
 * Seeder classes for npm run seed:run and POSBackend.exe --seed.
 * Auto-synced by scripts/sync-seeders-index.js when creating seeders.
 */
// Order matters — each seeder must run after its dependencies.
export const seeders: Array<new () => Seeder> = [
  // ── Tier 1: no inter-seeder dependencies ──────────────────────────────
  UsersSeeder,
  CurrenciesSeeder,
  TaxCategoriesSeeder,
  UomSeeder,
  MaterialTypesSeeder,
  InventoryTypesSeeder,
  StoreMenusSeeder,

  // ── Tier 2: depends on Tier 1 ─────────────────────────────────────────
  ModifierGroupsSeeder,
  ProductGroupsSeeder,
  MaterialsSeeder,          // needs UomSeeder + MaterialTypesSeeder

  // ── Tier 3: depends on Tier 2 ─────────────────────────────────────────
  ModifierOptionsSeeder,    // needs ModifierGroupsSeeder
  ProductsSeeder,           // needs ProductGroupsSeeder

  // ── Tier 4: depends on Tier 3 ─────────────────────────────────────────
  ProductVariantsSeeder,            // needs ProductsSeeder
  ProductGroupModifierGroupsSeeder, // needs ProductGroupsSeeder + ModifierGroupsSeeder
  ProductModifierGroupsSeeder,      // needs ProductsSeeder + ModifierGroupsSeeder
  RecipesSeeder,                    // needs ProductsSeeder

  // ── Tier 5: depends on Tier 4 ─────────────────────────────────────────
  RecipeItemsSeeder,        // needs RecipesSeeder + MaterialsSeeder
  MenuItemsSeeder,          // needs StoreMenusSeeder + ProductsSeeder/ProductVariantsSeeder
  InventoryStocksSeeder,    // needs ProductsSeeder/ProductVariantsSeeder

  // ── Tier 6: depends on Tier 5 ─────────────────────────────────────────
  MenuItemModifiersSeeder,  // needs MenuItemsSeeder + ModifierOptionsSeeder

  // ── No strict dependency, placed last for safety ──────────────────────
  DiscountsSeeder,
];
