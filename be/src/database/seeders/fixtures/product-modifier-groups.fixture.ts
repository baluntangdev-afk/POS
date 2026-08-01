export interface ProductModifierGroupLink {
  productName: string;
  modifierGroupName: string;
  sortOrder: number;
}

// Product-level modifier group links.
// Group-level defaults (Temperature, Size, Sugar Level for beverages)
// are handled in product-group-modifier-groups.fixture.ts.
// Add per-product overrides here only when a product needs modifiers beyond its group defaults.
export const PRODUCT_MODIFIER_GROUPS_FIXTURE: ProductModifierGroupLink[] = [];
