export interface ProductFixtureItem {
  name: string;
  groupName: 'Food' | 'Coffee, Drinks & Ice Cream' | 'Baking & Pastry';
  description: string;
  price: string;
  sortOrder: number;
}

export const PRODUCTS_SEEDER_FIXTURE: ProductFixtureItem[] = [
  // ── Food → Set Meal ──────────────────────────────────────────────────────
  { name: 'Set Meal (Salmon)',         groupName: 'Food', description: 'Choose Teriyaki, Parmesan, or Hot and Smoky', price: '455.00', sortOrder:  1 },
  { name: 'Set Meal (Beef)',           groupName: 'Food', description: 'Choose Teriyaki, Parmesan, or Hot and Smoky', price: '350.00', sortOrder:  2 },
  { name: 'Set Meal (Chicken)',        groupName: 'Food', description: 'Choose Teriyaki, Parmesan, or Hot and Smoky', price: '245.00', sortOrder:  3 },
  { name: 'Set Meal (Pork)',           groupName: 'Food', description: 'Choose Teriyaki, Parmesan, or Hot and Smoky', price: '245.00', sortOrder:  4 },

  // ── Food → Pasta ─────────────────────────────────────────────────────────
  { name: 'Pasta',                     groupName: 'Food', description: 'Choice of Lasagna or Mac and Cheese',         price: '285.00', sortOrder:  5 },

  // ── Food → A la Carte ────────────────────────────────────────────────────
  { name: 'American Breakfast',        groupName: 'Food', description: 'Full American breakfast plate',               price: '295.00', sortOrder:  6 },
  { name: 'Carbonara',                 groupName: 'Food', description: 'Classic creamy carbonara pasta',              price: '365.00', sortOrder:  7 },
  { name: 'Chicken Schnitzel',         groupName: 'Food', description: 'Breaded and pan-fried chicken',               price: '295.00', sortOrder:  8 },
  { name: 'Fries and Nuggets',         groupName: 'Food', description: 'Crispy fries with chicken nuggets',           price: '199.00', sortOrder:  9 },
  { name: 'Pinoy Breakfast (Chorizo)', groupName: 'Food', description: 'Filipino breakfast with chorizo',             price: '295.00', sortOrder: 10 },
  { name: 'Pinoy Breakfast (Tapa)',    groupName: 'Food', description: 'Filipino breakfast with tapa',                price: '295.00', sortOrder: 11 },
  { name: 'Pork Schnitzel',            groupName: 'Food', description: 'Breaded and pan-fried pork',                  price: '295.00', sortOrder: 12 },
  { name: 'UFO Classic Burger',        groupName: 'Food', description: 'House-style UFO burger',                      price: '350.00', sortOrder: 13 },
  { name: 'X English Breakfast',       groupName: 'Food', description: 'Full English breakfast plate',                price: '295.00', sortOrder: 14 },

  // ── Coffee, Drinks & Ice Cream → Coffee ──────────────────────────────────
  { name: 'Espresso',                  groupName: 'Coffee, Drinks & Ice Cream', description: 'Single or double shot espresso',                  price: '110.00', sortOrder:  1 },
  { name: 'Cafe Americano',            groupName: 'Coffee, Drinks & Ice Cream', description: 'Espresso with hot or iced water',                  price: '145.00', sortOrder:  2 },
  { name: 'Cafe Latte',                groupName: 'Coffee, Drinks & Ice Cream', description: 'Espresso with steamed or iced milk',               price: '165.00', sortOrder:  3 },
  { name: 'Cafe Mocha',                groupName: 'Coffee, Drinks & Ice Cream', description: 'Espresso with chocolate and milk',                 price: '170.00', sortOrder:  4 },
  { name: 'Spanish Latte',             groupName: 'Coffee, Drinks & Ice Cream', description: 'Espresso with condensed and fresh milk',           price: '160.00', sortOrder:  5 },
  { name: 'Caramel Macchiato',         groupName: 'Coffee, Drinks & Ice Cream', description: 'Espresso with caramel and milk',                   price: '170.00', sortOrder:  6 },
  { name: 'White Choco Mocha',         groupName: 'Coffee, Drinks & Ice Cream', description: 'Espresso with white chocolate and milk',           price: '160.00', sortOrder:  7 },
  { name: 'Dirty Matcha',              groupName: 'Coffee, Drinks & Ice Cream', description: 'Matcha with espresso shot',                        price: '175.00', sortOrder:  8 },
  { name: 'Mochaccino',                groupName: 'Coffee, Drinks & Ice Cream', description: 'Blended mocha coffee drink',                       price: '200.00', sortOrder:  9 },
  { name: 'Mocha Chips',               groupName: 'Coffee, Drinks & Ice Cream', description: 'Blended mocha with chocolate chips',               price: '220.00', sortOrder: 10 },
  { name: 'Cookie Crumble',            groupName: 'Coffee, Drinks & Ice Cream', description: 'Blended coffee with cookie crumble',               price: '220.00', sortOrder: 11 },
  { name: 'White Choco Mocha Blended', groupName: 'Coffee, Drinks & Ice Cream', description: 'Blended white chocolate mocha',                    price: '200.00', sortOrder: 12 },

  // ── Coffee, Drinks & Ice Cream → Non Coffee ──────────────────────────────
  { name: 'Ube',                       groupName: 'Coffee, Drinks & Ice Cream', description: 'Ube flavored hot, iced, or blended drink',         price: '100.00', sortOrder: 13 },
  { name: 'Mango',                     groupName: 'Coffee, Drinks & Ice Cream', description: 'Mango flavored hot, iced, or blended drink',       price: '100.00', sortOrder: 14 },
  { name: 'Matcha',                    groupName: 'Coffee, Drinks & Ice Cream', description: 'Matcha flavored hot, iced, or blended drink',      price: '120.00', sortOrder: 15 },
  { name: 'Red Velvet',                groupName: 'Coffee, Drinks & Ice Cream', description: 'Red velvet hot, iced, or blended drink',           price: '110.00', sortOrder: 16 },
  { name: 'Chocolate',                 groupName: 'Coffee, Drinks & Ice Cream', description: 'Chocolate flavored hot, iced, or blended',         price: '100.00', sortOrder: 17 },
  { name: 'Strawberry',                groupName: 'Coffee, Drinks & Ice Cream', description: 'Strawberry iced or blended drink',                 price: '120.00', sortOrder: 18 },
  { name: 'Biscoff',                   groupName: 'Coffee, Drinks & Ice Cream', description: 'Biscoff iced or blended drink',                    price: '210.00', sortOrder: 19 },
  { name: 'Ube Float',                 groupName: 'Coffee, Drinks & Ice Cream', description: 'Ube float drink',                                  price: '230.00', sortOrder: 20 },
  { name: 'Cucumber Lemonade',         groupName: 'Coffee, Drinks & Ice Cream', description: 'Refreshing cucumber lemonade',                     price: '110.00', sortOrder: 21 },
  { name: 'Red Passion',               groupName: 'Coffee, Drinks & Ice Cream', description: 'Red passion iced drink',                           price: '160.00', sortOrder: 22 },

  // ── Coffee, Drinks & Ice Cream → Gelato ──────────────────────────────────
  { name: 'Gelato',                    groupName: 'Coffee, Drinks & Ice Cream', description: 'Artisan gelato — choice of 13 flavors',            price: '130.00', sortOrder: 23 },

  // ── Coffee, Drinks & Ice Cream → Premium Fruit Shake ─────────────────────
  { name: 'Premium Fruit Shake',       groupName: 'Coffee, Drinks & Ice Cream', description: 'Premium blended fruit shake',                      price: '180.00', sortOrder: 24 },

  // ── Baking & Pastry → Croffle ─────────────────────────────────────────────
  { name: 'Croffle',                   groupName: 'Baking & Pastry', description: 'Crispy croissant waffle — choice of 4 flavors',              price: '190.00', sortOrder:  1 },
];
