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
export const seeders: Array<new () => Seeder> = [
  // Tier 0: no dependencies
  CurrenciesSeeder,
  TaxCategoriesSeeder,
  InventoryTypesSeeder,
  // Tier 1: admin user + no other seeder deps
  UsersSeeder,
  DiscountsSeeder,
  ModifierGroupsSeeder,
  ProductGroupsSeeder,
  StoreMenusSeeder,
  UomSeeder,
  MaterialTypesSeeder,
  // Tier 2: depends on Tier 1 data
  MaterialsSeeder,           // needs MaterialTypesSeeder + UomSeeder
  ModifierOptionsSeeder,     // needs ModifierGroupsSeeder
  ProductsSeeder,            // needs ProductGroupsSeeder
  ProductGroupModifierGroupsSeeder, // needs ProductGroupsSeeder + ModifierGroupsSeeder
  // Tier 3: depends on Tier 2 data
  InventoryStocksSeeder,     // needs MaterialsSeeder
  ProductVariantsSeeder,     // needs ProductsSeeder
  ProductModifierGroupsSeeder, // needs ProductsSeeder + ModifierGroupsSeeder
  // Tier 4: depends on Tier 3 data
  RecipesSeeder,             // needs ProductVariantsSeeder + UomSeeder
  MenuItemsSeeder,           // needs StoreMenusSeeder + ProductVariantsSeeder
  // Tier 5: depends on Tier 4 data
  MenuItemModifiersSeeder,   // needs MenuItemsSeeder + ModifierGroupsSeeder
  RecipeItemsSeeder,         // needs RecipesSeeder + MaterialsSeeder
];
