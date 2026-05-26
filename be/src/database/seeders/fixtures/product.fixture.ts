import * as fs from 'fs';
import * as path from 'path';
import { getAssetsPath } from '../../../utils/path.helper';

export interface ProductFixtureItem {
  name: string;
  groupName: 'Burgers' | 'Chicken' | 'Rice Meals' | 'Sides' | 'Beverages';
  description: string;
  price: string;
  sortOrder: number;
  imageFileName?: string;
  imageBase64: string;
}

const TINY_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

export const PRODUCTS_SEEDER_FIXTURE: ProductFixtureItem[] = [
  // Burgers
  { name: 'Classic Burger',       groupName: 'Burgers',    description: 'Juicy beef patty with lettuce, tomato, and pickles',            price: '149.00', sortOrder: 0, imageBase64: TINY_PNG_BASE64 },
  { name: 'Cheese Burger',        groupName: 'Burgers',    description: 'Classic burger topped with melted cheddar cheese',              price: '169.00', sortOrder: 1, imageBase64: TINY_PNG_BASE64 },
  { name: 'BBQ Bacon Burger',     groupName: 'Burgers',    description: 'Smoky BBQ sauce, crispy bacon, and caramelised onions',         price: '199.00', sortOrder: 2, imageBase64: TINY_PNG_BASE64 },
  { name: 'Double Patty Burger',  groupName: 'Burgers',    description: 'Two beef patties stacked with all the fixings',                 price: '219.00', sortOrder: 3, imageBase64: TINY_PNG_BASE64 },
  { name: 'Spicy Burger',         groupName: 'Burgers',    description: 'Fiery burger with chili mayo and pepper jack cheese',           price: '179.00', sortOrder: 4, imageBase64: TINY_PNG_BASE64 },
  { name: 'Mushroom Swiss Burger',groupName: 'Burgers',    description: 'Beef patty topped with sautéed mushrooms and Swiss cheese',     price: '189.00', sortOrder: 5, imageBase64: TINY_PNG_BASE64 },
  { name: 'Fish Fillet Burger',   groupName: 'Burgers',    description: 'Crispy fish fillet with tartar sauce on a soft bun',            price: '159.00', sortOrder: 6, imageBase64: TINY_PNG_BASE64 },
  { name: 'Crispy Chicken Burger',groupName: 'Burgers',    description: 'Crunchy fried chicken fillet with honey mustard dressing',      price: '175.00', sortOrder: 7, imageBase64: TINY_PNG_BASE64 },

  // Chicken
  { name: 'Crispy Fried Chicken',    groupName: 'Chicken', description: 'Golden crispy chicken with a seasoned herb coating',           price: '169.00', sortOrder: 0, imageBase64: TINY_PNG_BASE64 },
  { name: 'Grilled Chicken',         groupName: 'Chicken', description: 'Chargrilled chicken breast served with dipping sauce',         price: '189.00', sortOrder: 1, imageBase64: TINY_PNG_BASE64 },
  { name: 'Chicken Sandwich',        groupName: 'Chicken', description: 'Tender crispy chicken fillet on a toasted brioche bun',        price: '159.00', sortOrder: 2, imageBase64: TINY_PNG_BASE64 },
  { name: 'Chicken Wings (6 pcs)',   groupName: 'Chicken', description: 'Crispy wings tossed in your choice of sauce',                  price: '199.00', sortOrder: 3, imageBase64: TINY_PNG_BASE64 },
  { name: 'Spicy Chicken Sandwich',  groupName: 'Chicken', description: 'Fiery fried chicken with sriracha mayo and pickled slaw',      price: '175.00', sortOrder: 4, imageBase64: TINY_PNG_BASE64 },
  { name: 'Chicken Strips (4 pcs)',  groupName: 'Chicken', description: 'Tender breaded chicken strips with your choice of dip',        price: '159.00', sortOrder: 5, imageBase64: TINY_PNG_BASE64 },

  // Rice Meals
  { name: 'Chicken Rice Bowl', groupName: 'Rice Meals', description: 'Seasoned chicken over steamed rice with garlic sauce',            price: '179.00', sortOrder: 0, imageBase64: TINY_PNG_BASE64 },
  { name: 'Beef Rice Bowl',    groupName: 'Rice Meals', description: 'Tender beef strips on a bed of garlic fried rice',                price: '189.00', sortOrder: 1, imageBase64: TINY_PNG_BASE64 },
  { name: 'Pork Sisig',        groupName: 'Rice Meals', description: 'Sizzling chopped pork with calamansi, chili, and egg',            price: '199.00', sortOrder: 2, imageBase64: TINY_PNG_BASE64 },
  { name: 'Tapsilog',          groupName: 'Rice Meals', description: 'Marinated beef tapa, sinangag, and fried egg',                   price: '189.00', sortOrder: 3, imageBase64: TINY_PNG_BASE64 },
  { name: 'Longganisa Rice',   groupName: 'Rice Meals', description: 'Sweet pork longganisa served with garlic fried rice and egg',     price: '169.00', sortOrder: 4, imageBase64: TINY_PNG_BASE64 },
  { name: 'Bangus Rice Bowl',  groupName: 'Rice Meals', description: 'Grilled milkfish belly on steamed rice with sawsawan',           price: '185.00', sortOrder: 5, imageBase64: TINY_PNG_BASE64 },

  // Sides
  { name: 'French Fries',       groupName: 'Sides', description: 'Golden crispy fries, perfectly salted',                              price: '79.00',  sortOrder: 0, imageBase64: TINY_PNG_BASE64 },
  { name: 'Onion Rings',        groupName: 'Sides', description: 'Beer-battered onion rings with dipping sauce',                       price: '89.00',  sortOrder: 1, imageBase64: TINY_PNG_BASE64 },
  { name: 'Coleslaw',           groupName: 'Sides', description: 'Creamy coleslaw with a tangy dressing',                              price: '59.00',  sortOrder: 2, imageBase64: TINY_PNG_BASE64 },
  { name: 'Garlic Bread',       groupName: 'Sides', description: 'Toasted bread with herb garlic butter',                              price: '49.00',  sortOrder: 3, imageBase64: TINY_PNG_BASE64 },
  { name: 'Mozzarella Sticks',  groupName: 'Sides', description: 'Crispy breaded mozzarella sticks with marinara dip',                 price: '99.00',  sortOrder: 4, imageBase64: TINY_PNG_BASE64 },
  { name: 'Loaded Fries',       groupName: 'Sides', description: 'Crispy fries topped with cheese sauce, bacon, and jalapeños',        price: '119.00', sortOrder: 5, imageBase64: TINY_PNG_BASE64 },
  { name: 'Corn Soup',          groupName: 'Sides', description: 'Creamy sweet corn soup, a Filipino comfort classic',                 price: '69.00',  sortOrder: 6, imageBase64: TINY_PNG_BASE64 },

  // Beverages
  { name: 'Lemonade',            groupName: 'Beverages', description: 'Freshly squeezed lemonade, sweet and tart',                     price: '65.00',  sortOrder: 0, imageBase64: TINY_PNG_BASE64 },
  { name: 'Iced Tea',            groupName: 'Beverages', description: 'Chilled brewed tea served over ice',                            price: '55.00',  sortOrder: 1, imageBase64: TINY_PNG_BASE64 },
  { name: 'Cold Brew Coffee',    groupName: 'Beverages', description: 'Smooth cold-steeped coffee concentrate over ice',               price: '85.00',  sortOrder: 2, imageBase64: TINY_PNG_BASE64 },
  { name: 'Mineral Water',       groupName: 'Beverages', description: 'Chilled bottled mineral water',                                 price: '35.00',  sortOrder: 3, imageBase64: TINY_PNG_BASE64 },
  { name: 'Mango Shake',         groupName: 'Beverages', description: 'Thick and creamy shake made from ripe Philippine mangoes',      price: '95.00',  sortOrder: 4, imageBase64: TINY_PNG_BASE64 },
  { name: 'Chocolate Milkshake', groupName: 'Beverages', description: 'Rich and indulgent chocolate milkshake',                       price: '109.00', sortOrder: 5, imageBase64: TINY_PNG_BASE64 },
  { name: 'Soda (Can)',          groupName: 'Beverages', description: 'Assorted canned sodas — ask your cashier for available flavors', price: '45.00',  sortOrder: 6, imageBase64: TINY_PNG_BASE64 },
  { name: 'Calamansi Juice',     groupName: 'Beverages', description: 'Refreshing juice from fresh Philippine calamansi',              price: '65.00',  sortOrder: 7, imageBase64: TINY_PNG_BASE64 },
];

const ASSETS_SUBDIR_BY_GROUP: Record<ProductFixtureItem['groupName'], string> = {
  Burgers: 'burger-products',
  Chicken: 'chicken-products',
  'Rice Meals': 'rice-meal-products',
  Sides: 'sides-products',
  Beverages: 'beverage-products',
};

export function getProductImageBuffer(item: ProductFixtureItem): Buffer {
  const assetsSubdir = ASSETS_SUBDIR_BY_GROUP[item.groupName];
  const dirPath = path.join(getAssetsPath(), assetsSubdir);
  if (item.imageFileName) {
    const filePath = path.join(dirPath, item.imageFileName);
    if (fs.existsSync(filePath)) {
      return fs.readFileSync(filePath);
    }
  }
  if (fs.existsSync(dirPath)) {
    const files = fs.readdirSync(dirPath).filter((f) => /\.(png|jpg|jpeg|gif|webp)$/i.test(f));
    if (files.length > 0) {
      const randomFile = files[Math.floor(Math.random() * files.length)];
      return fs.readFileSync(path.join(dirPath, randomFile));
    }
  }
  return Buffer.from(item.imageBase64, 'base64');
}
