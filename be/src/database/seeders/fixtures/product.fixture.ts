export interface ProductFixtureItem {
  name: string;
  groupName:
    | 'Coffee'
    | 'Non-Coffee'
    | 'Gelato'
    | 'Fruit Shake'
    | 'Fruit Boost'
    | 'Meals';
  description: string;
  price: string;
  sortOrder: number;
}

export const PRODUCTS_SEEDER_FIXTURE: ProductFixtureItem[] = [
  // ─────────────────────────────────────────────────────────────
  // Coffee
  // ─────────────────────────────────────────────────────────────
  {
    name: 'Espresso',
    groupName: 'Coffee',
    description: 'Hot espresso',
    price: '110.00',
    sortOrder: 1,
  },
  {
    name: 'Cafe Latte',
    groupName: 'Coffee',
    description: 'Hot or iced latte',
    price: '165.00',
    sortOrder: 2,
  },
  {
    name: 'Cafe Mocha',
    groupName: 'Coffee',
    description: 'Hot or iced mocha',
    price: '170.00',
    sortOrder: 3,
  },
  {
    name: 'Spanish Latte',
    groupName: 'Coffee',
    description: 'Hot or iced Spanish latte',
    price: '160.00',
    sortOrder: 4,
  },
  {
    name: 'Cafe Americano',
    groupName: 'Coffee',
    description: 'Hot or iced americano',
    price: '145.00',
    sortOrder: 5,
  },
  {
    name: 'Caramel Macchiato',
    groupName: 'Coffee',
    description: 'Hot or iced caramel macchiato',
    price: '170.00',
    sortOrder: 6,
  },
  {
    name: 'White Chocolate Mocha',
    groupName: 'Coffee',
    description: 'Hot or iced white chocolate mocha',
    price: '160.00',
    sortOrder: 7,
  },
  {
    name: 'Dirty Matcha',
    groupName: 'Coffee',
    description: 'Dirty matcha',
    price: '175.00',
    sortOrder: 8,
  },
  {
    name: 'Mochaccino',
    groupName: 'Coffee',
    description: 'Blended coffee',
    price: '200.00',
    sortOrder: 9,
  },
  {
    name: 'Mocha Chips',
    groupName: 'Coffee',
    description: 'Blended coffee with chocolate chips',
    price: '220.00',
    sortOrder: 10,
  },
  {
    name: 'Cookie Crumble',
    groupName: 'Coffee',
    description: 'Blended coffee with cookie crumble',
    price: '220.00',
    sortOrder: 11,
  },
  {
    name: 'White Choco Mocha',
    groupName: 'Coffee',
    description: 'Blended white chocolate mocha',
    price: '200.00',
    sortOrder: 12,
  },

  // ─────────────────────────────────────────────────────────────
  // Non-Coffee
  // ─────────────────────────────────────────────────────────────
  {
    name: 'Ube',
    groupName: 'Non-Coffee',
    description: 'Hot or iced ube drink',
    price: '100.00',
    sortOrder: 1,
  },
  {
    name: 'Mango',
    groupName: 'Non-Coffee',
    description: 'Hot or iced mango drink',
    price: '100.00',
    sortOrder: 2,
  },
  {
    name: 'Matcha',
    groupName: 'Non-Coffee',
    description: 'Hot or iced matcha drink',
    price: '120.00',
    sortOrder: 3,
  },
  {
    name: 'Red Velvet',
    groupName: 'Non-Coffee',
    description: 'Hot or iced red velvet drink',
    price: '110.00',
    sortOrder: 4,
  },
  {
    name: 'Chocolate',
    groupName: 'Non-Coffee',
    description: 'Hot or iced chocolate drink',
    price: '100.00',
    sortOrder: 5,
  },
  {
    name: 'Strawberry',
    groupName: 'Non-Coffee',
    description: 'Iced strawberry drink',
    price: '120.00',
    sortOrder: 6,
  },

  // ─────────────────────────────────────────────────────────────
  // Gelato
  // ─────────────────────────────────────────────────────────────
  {
    name: 'Soft Serve Ice Cream',
    groupName: 'Gelato',
    description: 'Premium soft serve ice cream',
    price: '120.00',
    sortOrder: 1,
  },

  // ─────────────────────────────────────────────────────────────
  // Fruit Shake
  // ─────────────────────────────────────────────────────────────
  {
    name: 'Ube Float',
    groupName: 'Fruit Shake',
    description: 'Premium ube fruit shake',
    price: '230.00',
    sortOrder: 1,
  },
  {
    name: 'Mango Float',
    groupName: 'Fruit Shake',
    description: 'Premium mango fruit shake',
    price: '180.00',
    sortOrder: 2,
  },
  {
    name: 'Strawberry Float',
    groupName: 'Fruit Shake',
    description: 'Premium strawberry fruit shake',
    price: '180.00',
    sortOrder: 3,
  },

  // ─────────────────────────────────────────────────────────────
  // Fruit Boost
  // ─────────────────────────────────────────────────────────────
  {
    name: 'Red Passion',
    groupName: 'Fruit Boost',
    description: 'Fruit tea',
    price: '160.00',
    sortOrder: 1,
  },
  {
    name: 'Yogurt Fruit Tea',
    groupName: 'Fruit Boost',
    description: 'Yogurt fruit tea',
    price: '160.00',
    sortOrder: 2,
  },
  {
    name: 'Cebuano Iced Tea',
    groupName: 'Fruit Boost',
    description: 'House iced tea',
    price: '160.00',
    sortOrder: 3,
  },
  {
    name: 'Classic Lemonade',
    groupName: 'Fruit Boost',
    description: 'Classic lemonade',
    price: '140.00',
    sortOrder: 4,
  },
  {
    name: 'Cucumber Lemonade',
    groupName: 'Fruit Boost',
    description: 'Cucumber lemonade',
    price: '150.00',
    sortOrder: 5,
  },

  // ─────────────────────────────────────────────────────────────
  // Meals
  // ─────────────────────────────────────────────────────────────
  {
    name: 'Pinoy Breakfast',
    groupName: 'Meals',
    description: 'Choice of tapa or chorizo',
    price: '295.00',
    sortOrder: 1,
  },
  {
    name: 'American Breakfast',
    groupName: 'Meals',
    description: 'American breakfast meal',
    price: '295.00',
    sortOrder: 2,
  },
  {
    name: 'Chicken Schnitzel',
    groupName: 'Meals',
    description: 'Chicken schnitzel breakfast meal',
    price: '345.00',
    sortOrder: 3,
  },
  {
    name: 'Pork Schnitzel',
    groupName: 'Meals',
    description: 'Pork schnitzel breakfast meal',
    price: '345.00',
    sortOrder: 4,
  },
  {
    name: 'Teriyaki',
    groupName: 'Meals',
    description: 'Set meal',
    price: '245.00',
    sortOrder: 5,
  },
  {
    name: 'Parmesan',
    groupName: 'Meals',
    description: 'Set meal',
    price: '245.00',
    sortOrder: 6,
  },
  {
    name: 'Hot & Smoky',
    groupName: 'Meals',
    description: 'Set meal',
    price: '245.00',
    sortOrder: 7,
  },
];