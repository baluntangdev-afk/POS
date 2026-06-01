export interface ProductVariantFixtureItem {
  productName: string;
  variants: { name: string; price: number }[];
}

export const PRODUCT_VARIANTS_FIXTURE: ProductVariantFixtureItem[] = [
  // ── Food → Set Meal ──────────────────────────────────────────────────────
  { productName: 'Set Meal (Salmon)',         variants: [{ name: 'Salmon Teriyaki', price: 455 }, { name: 'Salmon Parmesan', price: 455 }, { name: 'Salmon Hot and Smoky', price: 455 }] },
  { productName: 'Set Meal (Beef)',           variants: [{ name: 'Beef Teriyaki', price: 350 }, { name: 'Beef Hot and Smoky', price: 360 }, { name: 'Beef Parmesan', price: 380 }] },
  { productName: 'Set Meal (Chicken)',        variants: [{ name: 'Chicken Teriyaki', price: 245 }, { name: 'Chicken Parmesan', price: 245 }, { name: 'Chicken Hot and Smoky', price: 245 }] },
  { productName: 'Set Meal (Pork)',           variants: [{ name: 'Pork Teriyaki', price: 245 }, { name: 'Pork Parmesan', price: 245 }, { name: 'Pork Hot and Smoky', price: 245 }] },

  // ── Food → Pasta ─────────────────────────────────────────────────────────
  { productName: 'Pasta',                     variants: [{ name: 'Lasagna', price: 285 }, { name: 'Mac and Cheese', price: 245 }] },

  // ── Food → A la Carte ────────────────────────────────────────────────────
  { productName: 'American Breakfast',        variants: [{ name: 'A la Carte', price: 295 }] },
  { productName: 'Carbonara',                 variants: [{ name: 'A la Carte', price: 365 }] },
  { productName: 'Chicken Schnitzel',         variants: [{ name: 'A la Carte', price: 295 }] },
  { productName: 'Fries and Nuggets',         variants: [{ name: 'A la Carte', price: 199 }] },
  { productName: 'Pinoy Breakfast (Chorizo)', variants: [{ name: 'A la Carte', price: 295 }] },
  { productName: 'Pinoy Breakfast (Tapa)',    variants: [{ name: 'A la Carte', price: 295 }] },
  { productName: 'Pork Schnitzel',            variants: [{ name: 'A la Carte', price: 295 }] },
  { productName: 'UFO Classic Burger',        variants: [{ name: 'A la Carte', price: 350 }] },
  { productName: 'X English Breakfast',       variants: [{ name: 'A la Carte', price: 295 }] },

  // ── Coffee ────────────────────────────────────────────────────────────────
  { productName: 'Espresso',                  variants: [{ name: 'Primo (Hot)', price: 110 }] },
  { productName: 'Cafe Americano',            variants: [{ name: 'Hot Primo', price: 145 }, { name: 'Hot Medio', price: 165 }, { name: 'Iced Medio', price: 160 }, { name: 'Iced Massimo', price: 175 }] },
  { productName: 'Cafe Latte',                variants: [{ name: 'Hot Primo', price: 165 }, { name: 'Hot Medio', price: 180 }, { name: 'Iced Medio', price: 180 }, { name: 'Iced Massimo', price: 195 }] },
  { productName: 'Cafe Mocha',                variants: [{ name: 'Hot Primo', price: 170 }, { name: 'Hot Medio', price: 185 }, { name: 'Iced Medio', price: 185 }, { name: 'Iced Massimo', price: 200 }] },
  { productName: 'Spanish Latte',             variants: [{ name: 'Hot Primo', price: 160 }, { name: 'Hot Medio', price: 180 }, { name: 'Iced Medio', price: 180 }, { name: 'Iced Massimo', price: 195 }] },
  { productName: 'Caramel Macchiato',         variants: [{ name: 'Hot Primo', price: 170 }, { name: 'Hot Medio', price: 185 }, { name: 'Iced Medio', price: 185 }, { name: 'Iced Massimo', price: 200 }] },
  { productName: 'White Choco Mocha',         variants: [{ name: 'Hot Primo', price: 160 }, { name: 'Hot Medio', price: 180 }, { name: 'Iced Medio', price: 180 }, { name: 'Iced Massimo', price: 200 }] },
  { productName: 'Dirty Matcha',              variants: [{ name: 'Iced Medio', price: 175 }, { name: 'Iced Massimo', price: 195 }] },
  { productName: 'Mochaccino',                variants: [{ name: 'Medio', price: 200 }, { name: 'Massimo', price: 215 }] },
  { productName: 'Mocha Chips',               variants: [{ name: 'Medio', price: 220 }, { name: 'Massimo', price: 235 }] },
  { productName: 'Cookie Crumble',            variants: [{ name: 'Medio', price: 220 }, { name: 'Massimo', price: 240 }] },
  { productName: 'White Choco Mocha Blended', variants: [{ name: 'Medio (16oz)', price: 200 }, { name: 'Massimo (22oz)', price: 220 }] },

  // ── Non Coffee ────────────────────────────────────────────────────────────
  { productName: 'Ube',                       variants: [{ name: 'Hot Primo (8oz)', price: 100 }, { name: 'Hot Medio', price: 120 }, { name: 'Iced Medio', price: 120 }, { name: 'Blended Massimo', price: 150 }] },
  { productName: 'Mango',                     variants: [{ name: 'Hot Primo', price: 100 }, { name: 'Hot Medio', price: 120 }, { name: 'Iced Medio', price: 120 }, { name: 'Blended Massimo', price: 140 }] },
  { productName: 'Matcha',                    variants: [{ name: 'Hot Primo', price: 120 }, { name: 'Hot Medio', price: 140 }, { name: 'Iced Medio', price: 130 }, { name: 'Blended Massimo', price: 150 }] },
  { productName: 'Red Velvet',                variants: [{ name: 'Hot Primo', price: 110 }, { name: 'Hot Medio', price: 130 }, { name: 'Iced Medio', price: 130 }, { name: 'Blended Massimo', price: 150 }] },
  { productName: 'Chocolate',                 variants: [{ name: 'Hot Primo', price: 100 }, { name: 'Hot Medio', price: 120 }, { name: 'Iced Medio', price: 130 }, { name: 'Blended Massimo', price: 150 }] },
  { productName: 'Strawberry',                variants: [{ name: 'Iced Medio', price: 120 }, { name: 'Blended Massimo', price: 140 }] },
  { productName: 'Biscoff',                   variants: [{ name: 'Iced Medio (16oz)', price: 210 }] },
  { productName: 'Ube Float',                 variants: [{ name: 'Massimo', price: 230 }] },
  { productName: 'Cucumber Lemonade',         variants: [{ name: 'Iced Medio', price: 110 }] },
  { productName: 'Red Passion',               variants: [{ name: 'Iced Medio', price: 160 }] },

  // ── Gelato ────────────────────────────────────────────────────────────────
  { productName: 'Gelato',                    variants: [
    { name: 'Matcha', price: 130 }, { name: 'Tableya', price: 130 }, { name: 'Mango', price: 130 },
    { name: 'Cafe Mocha', price: 130 }, { name: 'Red Velvet', price: 130 }, { name: 'Milktea', price: 130 },
    { name: 'Ube', price: 130 }, { name: 'Charcoal', price: 130 }, { name: 'Vanilla', price: 130 },
    { name: 'Strawberry', price: 130 }, { name: 'Chocolate', price: 130 }, { name: 'Cookies and Cream', price: 130 },
    { name: 'Pistachio', price: 130 },
  ] },

  // ── Premium Fruit Shake ───────────────────────────────────────────────────
  { productName: 'Premium Fruit Shake',       variants: [{ name: 'Mango Float', price: 180 }, { name: 'Strawberry', price: 180 }] },

  // ── Baking & Pastry ───────────────────────────────────────────────────────
  { productName: 'Croffle',                   variants: [{ name: 'Matcha Croffle', price: 190 }, { name: 'Oreo Croffle', price: 190 }, { name: 'Biscoff Croffle', price: 190 }, { name: 'Choco Overload', price: 190 }] },
];
