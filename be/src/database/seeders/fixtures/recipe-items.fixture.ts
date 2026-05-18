/**
 * Recipe items seed data: which materials (by materialName from materials seeder) are suited for each product.
 * Each recipe (product variant) gets only these materials as recipe items.
 */
export interface RecipeItemsFixtureItem {
  /** Product name (from ProductsSeeder). All variants of this product share this material list. */
  productName: string;
  /** Material names (must match MATERIALS_FIXTURE materialName). */
  materialNames: string[];
  /** Material names that are add-ons (extra: true). */
  extraMaterialNames?: string[];
}

export const RECIPE_ITEMS_FIXTURE: RecipeItemsFixtureItem[] = [
  {
    productName: 'Latte',
    materialNames: ['Ice', 'Cup', 'Lid', 'Straw', 'Coffee Beans', 'Whole Milk'],
    extraMaterialNames: ['Vanilla Syrup', 'Caramel Syrup'],
  },
  {
    productName: 'Americano',
    materialNames: ['Ice', 'Cup', 'Lid', 'Straw', 'Coffee Beans', 'Filtered water'],
    extraMaterialNames: ['Vanilla Syrup', 'Caramel Syrup'],
  },
  {
    productName: 'Macchiato',
    materialNames: ['Cup', 'Lid', 'Straw', 'Coffee Beans', 'Whole Milk'],
    extraMaterialNames: ['Vanilla Syrup', 'Caramel Syrup'],
  },
  {
    productName: 'Matcha',
    materialNames: ['Ice', 'Cup', 'Lid', 'Straw', 'Filtered water', 'Oat Milk'],
    extraMaterialNames: ['Vanilla Syrup', 'Caramel Syrup'],
  },
  {
    productName: 'Muffin',
    materialNames: ['Muffin'],
  },
  {
    productName: 'Salad',
    materialNames: ['Salad'],
  },
  {
    productName: 'Club Sandwich',
    materialNames: ['Club Sandwich'],
  },
];
