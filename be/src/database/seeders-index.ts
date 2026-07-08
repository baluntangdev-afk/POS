import type { Seeder } from './seeders/seeder.interface';
import { UsersSeeder } from './seeders/users.seeder';
import { CurrenciesSeeder } from './seeders/currencies.seeder';
import { DiscountsSeeder } from './seeders/discounts.seeder';
import { TaxCategoriesSeeder } from './seeders/tax-categories.seeder';
import { UomSeeder } from './seeders/uom.seeder';
import { MaterialTypesSeeder } from './seeders/material-types.seeder';
import { InventoryTypesSeeder } from './seeders/inventory-types.seeder';
import { StoreMenusSeeder } from './seeders/store-menus.seeder';
import { ModifierGroupsSeeder } from './seeders/modifier-groups.seeder';
import { MaterialsSeeder } from './seeders/materials.seeder';
import { ModifierOptionsSeeder } from './seeders/modifier-options.seeder';
import { ProductGroupModifierGroupsSeeder } from './seeders/product-group-modifier-groups.seeder';
import { ProductModifierGroupsSeeder } from './seeders/product-modifier-groups.seeder';
import { RecipesSeeder } from './seeders/recipes.seeder';
import { RecipeItemsSeeder } from './seeders/recipe-items.seeder';
import { MenuItemsSeeder } from './seeders/menu-items.seeder';
import { InventoryStocksSeeder } from './seeders/inventory-stocks.seeder';
import { MenuItemModifiersSeeder } from './seeders/menu-item-modifiers.seeder';

/**
 * Seeder classes for npm run seed:run and POSBackend.exe --seed.
 * Auto-synced by scripts/sync-seeders-index.js when creating seeders.
 */
export const seeders: Array<new () => Seeder> = [
  UsersSeeder,
  CurrenciesSeeder,
  DiscountsSeeder,
  TaxCategoriesSeeder,
  UomSeeder,
  MaterialTypesSeeder,
  InventoryTypesSeeder,
  StoreMenusSeeder,
  ModifierGroupsSeeder,
  MaterialsSeeder,
  ModifierOptionsSeeder,
  ProductGroupModifierGroupsSeeder,
  ProductModifierGroupsSeeder,
  RecipesSeeder,
  RecipeItemsSeeder,
  MenuItemsSeeder,
  InventoryStocksSeeder,
  MenuItemModifiersSeeder,
];
