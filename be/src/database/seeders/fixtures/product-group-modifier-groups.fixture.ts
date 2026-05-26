export interface ProductGroupModifierGroupLink {
  productGroupName: string;
  modifierGroupName: string;
  sortOrder: number;
}

export const PRODUCT_GROUP_MODIFIER_GROUPS_FIXTURE: ProductGroupModifierGroupLink[] = [
  // Beverages — Size, Sugar Level, Temperature
  { productGroupName: 'Beverages',   modifierGroupName: 'Size',        sortOrder: 0 },
  { productGroupName: 'Beverages',   modifierGroupName: 'Sugar Level', sortOrder: 1 },
  { productGroupName: 'Beverages',   modifierGroupName: 'Temperature', sortOrder: 2 },

  // Burgers — Sauce
  { productGroupName: 'Burgers',     modifierGroupName: 'Sauce',       sortOrder: 0 },

  // Chicken — Sauce
  { productGroupName: 'Chicken',     modifierGroupName: 'Sauce',       sortOrder: 0 },

  // Rice Meals — Sauce
  { productGroupName: 'Rice Meals',  modifierGroupName: 'Sauce',       sortOrder: 0 },
];
