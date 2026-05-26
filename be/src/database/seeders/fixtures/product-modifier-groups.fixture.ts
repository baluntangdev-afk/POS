export interface ProductModifierGroupLink {
  productName: string;
  modifierGroupName: string;
  sortOrder: number;
}

export const PRODUCT_MODIFIER_GROUPS_FIXTURE: ProductModifierGroupLink[] = [
  // ── Burgers ──────────────────────────────────────────────────────────────
  { productName: 'Classic Burger',        modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Classic Burger',        modifierGroupName: 'Add-ons',    sortOrder: 1 },
  { productName: 'Classic Burger',        modifierGroupName: 'Sauce',      sortOrder: 2 },

  { productName: 'Cheese Burger',         modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Cheese Burger',         modifierGroupName: 'Add-ons',    sortOrder: 1 },
  { productName: 'Cheese Burger',         modifierGroupName: 'Sauce',      sortOrder: 2 },

  { productName: 'BBQ Bacon Burger',      modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'BBQ Bacon Burger',      modifierGroupName: 'Add-ons',    sortOrder: 1 },
  { productName: 'BBQ Bacon Burger',      modifierGroupName: 'Sauce',      sortOrder: 2 },

  { productName: 'Double Patty Burger',   modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Double Patty Burger',   modifierGroupName: 'Sauce',      sortOrder: 1 },

  { productName: 'Spicy Burger',          modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Spicy Burger',          modifierGroupName: 'Spice Level',sortOrder: 1 },
  { productName: 'Spicy Burger',          modifierGroupName: 'Sauce',      sortOrder: 2 },

  { productName: 'Mushroom Swiss Burger', modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Mushroom Swiss Burger', modifierGroupName: 'Add-ons',    sortOrder: 1 },
  { productName: 'Mushroom Swiss Burger', modifierGroupName: 'Sauce',      sortOrder: 2 },

  { productName: 'Fish Fillet Burger',    modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Fish Fillet Burger',    modifierGroupName: 'Sauce',      sortOrder: 1 },

  { productName: 'Crispy Chicken Burger', modifierGroupName: 'Size',       sortOrder: 0 },
  { productName: 'Crispy Chicken Burger', modifierGroupName: 'Add-ons',    sortOrder: 1 },
  { productName: 'Crispy Chicken Burger', modifierGroupName: 'Sauce',      sortOrder: 2 },

  // ── Chicken ───────────────────────────────────────────────────────────────
  { productName: 'Crispy Fried Chicken',   modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Crispy Fried Chicken',   modifierGroupName: 'Spice Level', sortOrder: 1 },

  { productName: 'Grilled Chicken',        modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Grilled Chicken',        modifierGroupName: 'Sauce',       sortOrder: 1 },

  { productName: 'Chicken Sandwich',       modifierGroupName: 'Add-ons',     sortOrder: 0 },
  { productName: 'Chicken Sandwich',       modifierGroupName: 'Sauce',       sortOrder: 1 },

  { productName: 'Chicken Wings (6 pcs)',  modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Chicken Wings (6 pcs)',  modifierGroupName: 'Spice Level', sortOrder: 1 },
  { productName: 'Chicken Wings (6 pcs)',  modifierGroupName: 'Sauce',       sortOrder: 2 },

  { productName: 'Spicy Chicken Sandwich', modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Spicy Chicken Sandwich', modifierGroupName: 'Add-ons',     sortOrder: 1 },
  { productName: 'Spicy Chicken Sandwich', modifierGroupName: 'Sauce',       sortOrder: 2 },

  { productName: 'Chicken Strips (4 pcs)', modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Chicken Strips (4 pcs)', modifierGroupName: 'Sauce',       sortOrder: 1 },

  // ── Rice Meals ────────────────────────────────────────────────────────────
  { productName: 'Chicken Rice Bowl', modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Chicken Rice Bowl', modifierGroupName: 'Add-ons',     sortOrder: 1 },

  { productName: 'Beef Rice Bowl',    modifierGroupName: 'Add-ons',     sortOrder: 0 },

  { productName: 'Pork Sisig',        modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Tapsilog',          modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Longganisa Rice',   modifierGroupName: 'Spice Level', sortOrder: 0 },
  { productName: 'Bangus Rice Bowl',  modifierGroupName: 'Spice Level', sortOrder: 0 },

  // ── Sides ─────────────────────────────────────────────────────────────────
  { productName: 'French Fries',      modifierGroupName: 'Size',  sortOrder: 0 },
  { productName: 'French Fries',      modifierGroupName: 'Sauce', sortOrder: 1 },

  { productName: 'Onion Rings',       modifierGroupName: 'Sauce', sortOrder: 0 },
  { productName: 'Mozzarella Sticks', modifierGroupName: 'Sauce', sortOrder: 0 },

  { productName: 'Loaded Fries',      modifierGroupName: 'Size',  sortOrder: 0 },
  { productName: 'Loaded Fries',      modifierGroupName: 'Sauce', sortOrder: 1 },

  // ── Beverages ─────────────────────────────────────────────────────────────
  { productName: 'Lemonade',            modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Lemonade',            modifierGroupName: 'Sugar Level', sortOrder: 1 },

  { productName: 'Iced Tea',            modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Iced Tea',            modifierGroupName: 'Sugar Level', sortOrder: 1 },

  { productName: 'Cold Brew Coffee',    modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Cold Brew Coffee',    modifierGroupName: 'Sugar Level', sortOrder: 1 },

  { productName: 'Mango Shake',         modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Mango Shake',         modifierGroupName: 'Sugar Level', sortOrder: 1 },

  { productName: 'Chocolate Milkshake', modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Chocolate Milkshake', modifierGroupName: 'Sugar Level', sortOrder: 1 },

  { productName: 'Calamansi Juice',     modifierGroupName: 'Size',        sortOrder: 0 },
  { productName: 'Calamansi Juice',     modifierGroupName: 'Sugar Level', sortOrder: 1 },

  // Coleslaw, Garlic Bread, Corn Soup, Mineral Water, Soda (Can) need no modifier groups
];
