export interface ProductGroupModifierGroupLink {
  productGroupName: string;
  modifierGroupName: string;
  sortOrder: number;
}

export const PRODUCT_GROUP_MODIFIER_GROUPS_FIXTURE: ProductGroupModifierGroupLink[] = [
  // Coffee, Drinks & Ice Cream — Temperature (Hot/Cold), Size, Sugar Level
  { productGroupName: 'Coffee, Drinks & Ice Cream', modifierGroupName: 'Temperature', sortOrder: 0 },
  { productGroupName: 'Coffee, Drinks & Ice Cream', modifierGroupName: 'Size',        sortOrder: 1 },
  { productGroupName: 'Coffee, Drinks & Ice Cream', modifierGroupName: 'Sugar Level', sortOrder: 2 },

  // Food — Add Drink upsell
  { productGroupName: 'Food', modifierGroupName: 'Add Drink', sortOrder: 0 },
];
