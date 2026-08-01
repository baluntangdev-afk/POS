export interface ProductVariantFixtureItem {
  productName: string;
  variants: { name: string; price: number }[];
}

export const PRODUCT_VARIANTS_FIXTURE: ProductVariantFixtureItem[] = [
  // ─────────────────────────────────────────────────────────────
  // Coffee
  // ─────────────────────────────────────────────────────────────
  {
    productName: 'Espresso',
    variants: [{ name: 'Primo', price: 110 }],
  },

  {
    productName: 'Cafe Latte',
    variants: [
      { name: 'Hot Primo', price: 165 },
      { name: 'Hot Medio', price: 180 },
      { name: 'Iced Medio', price: 180 },
      { name: 'Iced Massimo', price: 195 },
    ],
  },

  {
    productName: 'Cafe Mocha',
    variants: [
      { name: 'Hot Primo', price: 170 },
      { name: 'Hot Medio', price: 185 },
      { name: 'Iced Medio', price: 185 },
      { name: 'Iced Massimo', price: 200 },
    ],
  },

  {
    productName: 'Spanish Latte',
    variants: [
      { name: 'Hot Primo', price: 160 },
      { name: 'Hot Medio', price: 180 },
      { name: 'Iced Medio', price: 180 },
      { name: 'Iced Massimo', price: 195 },
    ],
  },

  {
    productName: 'Cafe Americano',
    variants: [
      { name: 'Hot Primo', price: 145 },
      { name: 'Hot Medio', price: 165 },
      { name: 'Iced Medio', price: 160 },
      { name: 'Iced Massimo', price: 175 },
    ],
  },

  {
    productName: 'Caramel Macchiato',
    variants: [
      { name: 'Hot Primo', price: 170 },
      { name: 'Hot Medio', price: 185 },
      { name: 'Iced Medio', price: 185 },
      { name: 'Iced Massimo', price: 200 },
    ],
  },

  {
    productName: 'White Chocolate Mocha',
    variants: [
      { name: 'Hot Primo', price: 160 },
      { name: 'Hot Medio', price: 180 },
      { name: 'Iced Medio', price: 180 },
      { name: 'Iced Massimo', price: 200 },
    ],
  },

  {
    productName: 'Dirty Matcha',
    variants: [
      { name: 'Iced Medio', price: 175 },
      { name: 'Iced Massimo', price: 195 },
    ],
  },

  {
    productName: 'Mochaccino',
    variants: [
      { name: 'Medio', price: 200 },
      { name: 'Massimo', price: 215 },
    ],
  },

  {
    productName: 'Mocha Chips',
    variants: [
      { name: 'Medio', price: 220 },
      { name: 'Massimo', price: 235 },
    ],
  },

  {
    productName: 'Cookie Crumble',
    variants: [
      { name: 'Medio', price: 220 },
      { name: 'Massimo', price: 240 },
    ],
  },

  {
    productName: 'White Choco Mocha',
    variants: [
      { name: 'Medio', price: 200 },
      { name: 'Massimo', price: 220 },
    ],
  },

  // ─────────────────────────────────────────────────────────────
  // Non-Coffee
  // ─────────────────────────────────────────────────────────────

  {
    productName: 'Ube',
    variants: [
      { name: 'Hot Primo', price: 100 },
      { name: 'Hot Medio', price: 120 },
      { name: 'Iced Medio', price: 120 },
      { name: 'Iced Massimo', price: 150 },
    ],
  },

  {
    productName: 'Mango',
    variants: [
      { name: 'Hot Primo', price: 100 },
      { name: 'Hot Medio', price: 120 },
      { name: 'Iced Medio', price: 120 },
      { name: 'Iced Massimo', price: 140 },
    ],
  },

  {
    productName: 'Matcha',
    variants: [
      { name: 'Hot Primo', price: 120 },
      { name: 'Hot Medio', price: 140 },
      { name: 'Iced Medio', price: 130 },
      { name: 'Iced Massimo', price: 150 },
    ],
  },

  {
    productName: 'Red Velvet',
    variants: [
      { name: 'Hot Primo', price: 110 },
      { name: 'Hot Medio', price: 130 },
    ],
  },

  {
    productName: 'Chocolate',
    variants: [
      { name: 'Hot Primo', price: 100 },
      { name: 'Hot Medio', price: 120 },
      { name: 'Iced Medio', price: 130 },
      { name: 'Iced Massimo', price: 150 },
    ],
  },

  {
    productName: 'Strawberry',
    variants: [
      { name: 'Iced Medio', price: 120 },
      { name: 'Iced Massimo', price: 140 },
    ],
  },

  // ─────────────────────────────────────────────────────────────
  // Gelato
  // ─────────────────────────────────────────────────────────────

  {
    productName: 'Soft Serve Ice Cream',
    variants: [
      { name: 'Mango 8oz', price: 120 },
      { name: 'Mango 12oz', price: 140 },

      { name: 'Strawberry 8oz', price: 120 },
      { name: 'Strawberry 12oz', price: 140 },

      { name: 'Chocolate 8oz', price: 120 },
      { name: 'Chocolate 12oz', price: 140 },

      { name: 'Ube 8oz', price: 120 },
      { name: 'Ube 12oz', price: 140 },

      { name: 'Matcha 8oz', price: 120 },
      { name: 'Matcha 12oz', price: 140 },

      { name: 'Charcoal 8oz', price: 120 },
      { name: 'Charcoal 12oz', price: 140 },

      { name: 'Vanilla 8oz', price: 120 },
      { name: 'Vanilla 12oz', price: 140 },

      { name: 'Tableya 8oz', price: 120 },
      { name: 'Tableya 12oz', price: 140 },
    ],
  },

  // ─────────────────────────────────────────────────────────────
  // Fruit Shake
  // ─────────────────────────────────────────────────────────────

  {
    productName: 'Ube Float',
    variants: [{ name: 'Massimo', price: 230 }],
  },

  {
    productName: 'Mango Float',
    variants: [{ name: 'Massimo', price: 180 }],
  },

  {
    productName: 'Strawberry Float',
    variants: [{ name: 'Massimo', price: 180 }],
  },

  // ─────────────────────────────────────────────────────────────
  // Fruit Boost
  // ─────────────────────────────────────────────────────────────

  {
    productName: 'Red Passion',
    variants: [{ name: 'Medio', price: 160 }],
  },

  {
    productName: 'Yogurt Fruit Tea',
    variants: [{ name: 'Medio', price: 160 }],
  },

  {
    productName: 'Cebuano Iced Tea',
    variants: [{ name: 'Medio', price: 160 }],
  },

  {
    productName: 'Classic Lemonade',
    variants: [{ name: 'Medio', price: 140 }],
  },

  {
    productName: 'Cucumber Lemonade',
    variants: [{ name: 'Medio', price: 150 }],
  },

  // ─────────────────────────────────────────────────────────────
  // Meals
  // ─────────────────────────────────────────────────────────────

  {
    productName: 'Pinoy Breakfast',
    variants: [
      { name: 'Tapa', price: 295 },
      { name: 'Chorizo', price: 295 },
    ],
  },

  {
    productName: 'American Breakfast',
    variants: [{ name: 'Regular', price: 295 }],
  },

  {
    productName: 'Chicken Schnitzel',
    variants: [{ name: 'Regular', price: 345 }],
  },

  {
    productName: 'Pork Schnitzel',
    variants: [{ name: 'Regular', price: 345 }],
  },

  {
    productName: 'Teriyaki',
    variants: [
      { name: 'Pork', price: 245 },
      { name: 'Chicken', price: 245 },
      { name: 'Beef', price: 350 },
      { name: 'Salmon', price: 455 },
    ],
  },

  {
    productName: 'Parmesan',
    variants: [
      { name: 'Pork', price: 245 },
      { name: 'Chicken', price: 245 },
      { name: 'Beef', price: 380 },
      { name: 'Salmon', price: 455 },
    ],
  },

  {
    productName: 'Hot & Smoky',
    variants: [
      { name: 'Pork', price: 245 },
      { name: 'Chicken', price: 245 },
      { name: 'Beef', price: 360 },
      { name: 'Salmon', price: 455 },
    ],
  },
];