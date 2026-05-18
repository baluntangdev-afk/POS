/**
 * Modifier option seed data per modifier group.
 * - recipeItem: option linked to a recipe item (product variant + material)
 * - material: option linked to a material only
 * - nameOnly: display name only (e.g. Hot, Cold)
 */
export interface ModifierOptionRecipeItemRef {
  type: 'recipeItem';
  /** Product name (e.g. Muffin). */
  productName: string;
  /** Variant name (e.g. Regular). */
  variantName: string;
  /** Material name in that recipe (e.g. Muffin). */
  materialName: string;
  /** Optional price add-on (default 0 in seeder). */
  priceAddOn?: string;
}

export interface ModifierOptionMaterialRef {
  type: 'material';
  materialName: string;
  /** Optional price add-on (default 0 in seeder). */
  priceAddOn?: string;
}

export interface ModifierOptionNameOnly {
  type: 'nameOnly';
  /** Optional price add-on (default 0 in seeder). */
  priceAddOn?: string;
}

export type ModifierOptionFixtureItem =
  | (ModifierOptionRecipeItemRef & { name: string })
  | (ModifierOptionMaterialRef & { name: string })
  | (ModifierOptionNameOnly & { name: string });

export interface ModifierOptionsGroupFixture {
  modifierGroupName: string;
  options: ModifierOptionFixtureItem[];
}

export const MODIFIER_OPTIONS_FIXTURE: ModifierOptionsGroupFixture[] = [
  {
    modifierGroupName: 'Add-Ons',
    options: [
      {
        name: 'Muffin',
        type: 'recipeItem',
        productName: 'Muffin',
        variantName: 'Regular',
        materialName: 'Muffin',
        priceAddOn: '100',
      },
      {
        name: 'Salad',
        type: 'recipeItem',
        productName: 'Salad',
        variantName: 'Regular',
        materialName: 'Salad',
        priceAddOn: '100',
      },
    ],
  },
  {
    modifierGroupName: 'Temperature',
    options: [
      { name: 'Hot', type: 'nameOnly' },
      { name: 'Cold', type: 'nameOnly' },
    ],
  },
  {
    modifierGroupName: 'Add Syrup',
    options: [
      {
        name: 'Vanilla Syrup',
        type: 'recipeItem',
        productName: 'Latte',
        variantName: 'Regular',
        materialName: 'Vanilla Syrup',
        priceAddOn: '25',
      },
      {
        name: 'Caramel Syrup',
        type: 'recipeItem',
        productName: 'Latte',
        variantName: 'Regular',
        materialName: 'Caramel Syrup',
        priceAddOn: '30',
      },
    ],
  },
  {
    modifierGroupName: 'Add Drink',
    options: [
      { name: 'Coffee', type: 'nameOnly', priceAddOn: '100' },
      { name: 'Tea', type: 'nameOnly', priceAddOn: '100' },
    ],
  },
];
