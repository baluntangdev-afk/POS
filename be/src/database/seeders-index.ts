import type { Seeder } from './seeders/seeder.interface';
import { CurrenciesSeeder } from './seeders/currencies.seeder';
import { DiscountsSeeder } from './seeders/discounts.seeder';
import { InventoryStocksSeeder } from './seeders/inventory-stocks.seeder';
import { InventoryTypesSeeder } from './seeders/inventory-types.seeder';
import { MaterialTypesSeeder } from './seeders/material-types.seeder';
import { MaterialsSeeder } from './seeders/materials.seeder';
import { MenuItemsSeeder } from './seeders/menu-items.seeder';
import { ModifierGroupsSeeder } from './seeders/modifier-groups.seeder';
import { ModifierOptionsSeeder } from './seeders/modifier-options.seeder';
import { ProductGroupModifierGroupsSeeder } from './seeders/product-group-modifier-groups.seeder';
import { ProductGroupsSeeder } from './seeders/product-groups.seeder';
import { ProductModifierGroupsSeeder } from './seeders/product-modifier-groups.seeder';
import { ProductsSeeder } from './seeders/products.seeder';
import { ProductVariantsSeeder } from './seeders/product-variants.seeder';
import { RecipeItemsSeeder } from './seeders/recipe-items.seeder';
import { RecipesSeeder } from './seeders/recipes.seeder';
import { StoreMenusSeeder } from './seeders/store-menus.seeder';
import { TaxCategoriesSeeder } from './seeders/tax-categories.seeder';
import { UomSeeder } from './seeders/uom.seeder';
import { UsersSeeder } from './seeders/users.seeder';

export const seeders: Array<new () => Seeder> = [
  UsersSeeder,
  UomSeeder,
  CurrenciesSeeder,
  MaterialTypesSeeder,
  MaterialsSeeder,
  InventoryStocksSeeder,
  InventoryTypesSeeder,
  TaxCategoriesSeeder,
  DiscountsSeeder,
  ProductGroupsSeeder,
  ProductsSeeder,
  ProductVariantsSeeder,
  ModifierGroupsSeeder,
  ModifierOptionsSeeder,
  ProductGroupModifierGroupsSeeder,
  ProductModifierGroupsSeeder,
  StoreMenusSeeder,
  RecipesSeeder,
  MenuItemsSeeder,
  RecipeItemsSeeder,
];
