'use strict';

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.POSTGRES_HOST     || 'localhost',
  port:     parseInt(process.env.POSTGRES_PORT || '5432', 10),
  user:     process.env.POSTGRES_USER     || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'postgres',
  database: process.env.POSTGRES_DB       || 'pos_db',
});

// ── Helpers ────────────────────────────────────────────────────────────────────

async function upsertProductGroup(client, adminId, name, description) {
  const ex = await client.query(
    `SELECT id FROM product_groups WHERE name = $1 AND deleted_at IS NULL LIMIT 1`,
    [name],
  );
  if (ex.rows.length > 0) {
    await client.query(
      `UPDATE product_groups SET description=$2, status='Active' WHERE id=$1`,
      [ex.rows[0].id, description],
    );
    return ex.rows[0].id;
  }
  const r = await client.query(
    `INSERT INTO product_groups (name, description, status, created_by, updated_by)
     VALUES ($1, $2, 'Active', $3, $3) RETURNING id`,
    [name, description, adminId],
  );
  return r.rows[0].id;
}

async function upsertModifierGroup(client, adminId, name, minSel, maxSel, selType, isRequired, description) {
  const ex = await client.query(
    `SELECT id FROM modifier_groups WHERE name = $1 AND deleted_at IS NULL LIMIT 1`,
    [name],
  );
  if (ex.rows.length > 0) {
    await client.query(
      `UPDATE modifier_groups
         SET selection_type=$2, is_required=$3, description=$4,
             min_selection=$5, max_selection=$6
       WHERE id=$1`,
      [ex.rows[0].id, selType, isRequired, description, minSel, maxSel],
    );
    return ex.rows[0].id;
  }
  const r = await client.query(
    `INSERT INTO modifier_groups
       (name, min_selection, max_selection, selection_type, is_required, description, created_by, updated_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $7) RETURNING id`,
    [name, minSel, maxSel, selType, isRequired, description, adminId],
  );
  return r.rows[0].id;
}

async function upsertModifierOption(client, adminId, mgId, name, priceAddOn, sortOrder) {
  const ex = await client.query(
    `SELECT id FROM modifier_options
      WHERE modifier_group_id = $1 AND name = $2 AND deleted_at IS NULL LIMIT 1`,
    [mgId, name],
  );
  if (ex.rows.length > 0) {
    await client.query(
      `UPDATE modifier_options SET price_add_on=$2, sort_order=$3, is_available=true WHERE id=$1`,
      [ex.rows[0].id, priceAddOn, sortOrder],
    );
    return ex.rows[0].id;
  }
  const r = await client.query(
    `INSERT INTO modifier_options
       (modifier_group_id, name, price_add_on, is_available, sort_order, created_by, updated_by)
     VALUES ($1, $2, $3, true, $4, $5, $5) RETURNING id`,
    [mgId, name, priceAddOn, sortOrder, adminId],
  );
  return r.rows[0].id;
}

async function upsertProduct(client, adminId, groupId, name, description, price, sortOrder) {
  const ex = await client.query(
    `SELECT id FROM products WHERE name = $1 AND deleted_at IS NULL LIMIT 1`,
    [name],
  );
  if (ex.rows.length > 0) {
    await client.query(
      `UPDATE products
         SET group_id=$2, description=$3, price=$4, sort_order=$5,
             is_available=true, status='Active'
       WHERE id=$1`,
      [ex.rows[0].id, groupId, description, price, sortOrder],
    );
    return ex.rows[0].id;
  }
  const r = await client.query(
    `INSERT INTO products
       (group_id, name, description, price, is_available, sort_order, status, created_by, updated_by)
     VALUES ($1, $2, $3, $4, true, $5, 'Active', $6, $6) RETURNING id`,
    [groupId, name, description, price, sortOrder, adminId],
  );
  return r.rows[0].id;
}

async function linkProductModifier(client, productId, mgId, sortOrder) {
  await client.query(
    `INSERT INTO product_modifier_groups (product_id, modifier_group_id, sort_order)
     VALUES ($1, $2, $3)
     ON CONFLICT (product_id, modifier_group_id)
     DO UPDATE SET sort_order = EXCLUDED.sort_order`,
    [productId, mgId, sortOrder],
  );
}

// ── Seed ───────────────────────────────────────────────────────────────────────

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Admin user (required for created_by / updated_by FKs)
    const userResult = await client.query(
      `SELECT id FROM users WHERE deleted_at IS NULL ORDER BY id ASC LIMIT 1`,
    );
    if (userResult.rows.length === 0) {
      throw new Error('No users found – run UsersSeeder first (npm run seed:run).');
    }
    const adminId = userResult.rows[0].id;
    console.log(`  Admin user id=${adminId}`);

    // ── Product groups (kiosk categories) ─────────────────────────────────────
    const PG = {};
    PG.burgers    = await upsertProductGroup(client, adminId, 'Burgers',    'All our signature beef and chicken burgers');
    PG.chicken    = await upsertProductGroup(client, adminId, 'Chicken',    'Crispy and grilled chicken dishes');
    PG.riceMeals  = await upsertProductGroup(client, adminId, 'Rice Meals', 'Hearty rice bowls and Filipino favourites');
    PG.sides      = await upsertProductGroup(client, adminId, 'Sides',      'Perfect add-ons to complete your meal');
    PG.beverages  = await upsertProductGroup(client, adminId, 'Beverages',  'Cold drinks and refreshing beverages');
    console.log(`  ✓ Product groups: ${Object.keys(PG).length}`);

    // ── Modifier groups ────────────────────────────────────────────────────────
    const MG = {};
    MG.size       = await upsertModifierGroup(client, adminId, 'Size',        1, 1, 'single',   true,  'Choose your size');
    MG.spice      = await upsertModifierGroup(client, adminId, 'Spice Level', 0, 1, 'single',   false, 'How spicy do you like it?');
    MG.addons     = await upsertModifierGroup(client, adminId, 'Add-ons',     0, 5, 'multiple', false, 'Customise your meal');
    MG.sauce      = await upsertModifierGroup(client, adminId, 'Sauce',       0, 1, 'single',   false, 'Choose a dipping sauce');
    MG.sugarLevel = await upsertModifierGroup(client, adminId, 'Sugar Level', 1, 1, 'single',   true,  'Choose your sugar level');
    console.log(`  ✓ Modifier groups: ${Object.keys(MG).length}`);

    // ── Modifier options ───────────────────────────────────────────────────────
    // Size
    await upsertModifierOption(client, adminId, MG.size, 'Regular',      0.00, 0);
    await upsertModifierOption(client, adminId, MG.size, 'Large',       25.00, 1);
    await upsertModifierOption(client, adminId, MG.size, 'Extra Large', 45.00, 2);

    // Spice Level
    await upsertModifierOption(client, adminId, MG.spice, 'Mild',   0.00, 0);
    await upsertModifierOption(client, adminId, MG.spice, 'Medium', 0.00, 1);
    await upsertModifierOption(client, adminId, MG.spice, 'Hot',    0.00, 2);

    // Add-ons
    await upsertModifierOption(client, adminId, MG.addons, 'Extra Cheese', 15.00, 0);
    await upsertModifierOption(client, adminId, MG.addons, 'Bacon',        25.00, 1);
    await upsertModifierOption(client, adminId, MG.addons, 'Fried Egg',    20.00, 2);
    await upsertModifierOption(client, adminId, MG.addons, 'Avocado',      30.00, 3);
    await upsertModifierOption(client, adminId, MG.addons, 'Jalapeños',    10.00, 4);

    // Sauce
    await upsertModifierOption(client, adminId, MG.sauce, 'Ketchup',   0.00, 0);
    await upsertModifierOption(client, adminId, MG.sauce, 'Mustard',   0.00, 1);
    await upsertModifierOption(client, adminId, MG.sauce, 'Aioli',     0.00, 2);
    await upsertModifierOption(client, adminId, MG.sauce, 'BBQ Sauce', 0.00, 3);
    await upsertModifierOption(client, adminId, MG.sauce, 'Hot Sauce', 0.00, 4);

    // Sugar Level
    await upsertModifierOption(client, adminId, MG.sugarLevel, '0%',   0.00, 0);
    await upsertModifierOption(client, adminId, MG.sugarLevel, '25%',  0.00, 1);
    await upsertModifierOption(client, adminId, MG.sugarLevel, '50%',  0.00, 2);
    await upsertModifierOption(client, adminId, MG.sugarLevel, '75%',  0.00, 3);
    await upsertModifierOption(client, adminId, MG.sugarLevel, '100%', 0.00, 4);
    console.log('  ✓ Modifier options seeded');

    // ── Products ───────────────────────────────────────────────────────────────
    const P = {};

    // Burgers
    P.classicBurger      = await upsertProduct(client, adminId, PG.burgers,   'Classic Burger',       'Juicy beef patty with lettuce, tomato, and pickles',         149.00, 0);
    P.cheeseBurger       = await upsertProduct(client, adminId, PG.burgers,   'Cheese Burger',        'Classic burger topped with melted cheddar cheese',           169.00, 1);
    P.bbqBaconBurger     = await upsertProduct(client, adminId, PG.burgers,   'BBQ Bacon Burger',     'Smoky BBQ sauce, crispy bacon, and caramelised onions',      199.00, 2);
    P.doublePatty        = await upsertProduct(client, adminId, PG.burgers,   'Double Patty Burger',  'Two beef patties stacked with all the fixings',              219.00, 3);
    P.spicyBurger        = await upsertProduct(client, adminId, PG.burgers,   'Spicy Burger',         'Fiery burger with chili mayo and pepper jack cheese',        179.00, 4);
    P.mushroomBurger     = await upsertProduct(client, adminId, PG.burgers,   'Mushroom Swiss Burger','Beef patty topped with sautéed mushrooms and Swiss cheese',  189.00, 5);
    P.fishBurger         = await upsertProduct(client, adminId, PG.burgers,   'Fish Fillet Burger',   'Crispy fish fillet with tartar sauce on a soft bun',         159.00, 6);
    P.crispyChickenBurger= await upsertProduct(client, adminId, PG.burgers,   'Crispy Chicken Burger','Crunchy fried chicken fillet with honey mustard dressing',   175.00, 7);

    // Chicken
    P.friedChicken       = await upsertProduct(client, adminId, PG.chicken,   'Crispy Fried Chicken', 'Golden crispy chicken with a seasoned herb coating',         169.00, 0);
    P.grilledChicken     = await upsertProduct(client, adminId, PG.chicken,   'Grilled Chicken',      'Chargrilled chicken breast served with dipping sauce',       189.00, 1);
    P.chickenSandwich    = await upsertProduct(client, adminId, PG.chicken,   'Chicken Sandwich',     'Tender crispy chicken fillet on a toasted brioche bun',      159.00, 2);
    P.chickenWings       = await upsertProduct(client, adminId, PG.chicken,   'Chicken Wings (6 pcs)','Crispy wings tossed in your choice of sauce',                199.00, 3);
    P.spicyChickenSandwich= await upsertProduct(client, adminId, PG.chicken,  'Spicy Chicken Sandwich','Fiery fried chicken with sriracha mayo and pickled slaw',   175.00, 4);
    P.chickenStrips      = await upsertProduct(client, adminId, PG.chicken,   'Chicken Strips (4 pcs)','Tender breaded chicken strips with your choice of dip',     159.00, 5);

    // Rice Meals
    P.chickenRiceBowl    = await upsertProduct(client, adminId, PG.riceMeals, 'Chicken Rice Bowl',    'Seasoned chicken over steamed rice with garlic sauce',       179.00, 0);
    P.beefRiceBowl       = await upsertProduct(client, adminId, PG.riceMeals, 'Beef Rice Bowl',       'Tender beef strips on a bed of garlic fried rice',           189.00, 1);
    P.sisig              = await upsertProduct(client, adminId, PG.riceMeals, 'Pork Sisig',           'Sizzling chopped pork with calamansi, chili, and egg',       199.00, 2);
    P.tapsilog           = await upsertProduct(client, adminId, PG.riceMeals, 'Tapsilog',             'Marinated beef tapa, sinangag, and fried egg',               189.00, 3);
    P.longganisaRice     = await upsertProduct(client, adminId, PG.riceMeals, 'Longganisa Rice',      'Sweet pork longganisa served with garlic fried rice and egg',169.00, 4);
    P.bangusRice         = await upsertProduct(client, adminId, PG.riceMeals, 'Bangus Rice Bowl',     'Grilled milkfish belly on steamed rice with sawsawan',       185.00, 5);

    // Sides
    P.frenchFries        = await upsertProduct(client, adminId, PG.sides,     'French Fries',         'Golden crispy fries, perfectly salted',                       79.00, 0);
    P.onionRings         = await upsertProduct(client, adminId, PG.sides,     'Onion Rings',          'Beer-battered onion rings with dipping sauce',                89.00, 1);
    P.coleslaw           = await upsertProduct(client, adminId, PG.sides,     'Coleslaw',             'Creamy coleslaw with a tangy dressing',                       59.00, 2);
    P.garlicBread        = await upsertProduct(client, adminId, PG.sides,     'Garlic Bread',         'Toasted bread with herb garlic butter',                       49.00, 3);
    P.mozSticks          = await upsertProduct(client, adminId, PG.sides,     'Mozzarella Sticks',    'Crispy breaded mozzarella sticks with marinara dip',          99.00, 4);
    P.loadedFries        = await upsertProduct(client, adminId, PG.sides,     'Loaded Fries',         'Crispy fries topped with cheese sauce, bacon, and jalapeños', 119.00, 5);
    P.cornSoup           = await upsertProduct(client, adminId, PG.sides,     'Corn Soup',            'Creamy sweet corn soup, a Filipino comfort classic',           69.00, 6);

    // Beverages
    P.lemonade           = await upsertProduct(client, adminId, PG.beverages, 'Lemonade',             'Freshly squeezed lemonade, sweet and tart',                   65.00, 0);
    P.icedTea            = await upsertProduct(client, adminId, PG.beverages, 'Iced Tea',             'Chilled brewed tea served over ice',                          55.00, 1);
    P.coldCoffee         = await upsertProduct(client, adminId, PG.beverages, 'Cold Brew Coffee',     'Smooth cold-steeped coffee concentrate over ice',             85.00, 2);
    P.water              = await upsertProduct(client, adminId, PG.beverages, 'Mineral Water',        'Chilled bottled mineral water',                               35.00, 3);
    P.mangoShake         = await upsertProduct(client, adminId, PG.beverages, 'Mango Shake',          'Thick and creamy shake made from ripe Philippine mangoes',     95.00, 4);
    P.chocolateMilkshake = await upsertProduct(client, adminId, PG.beverages, 'Chocolate Milkshake',  'Rich and indulgent chocolate milkshake',                      109.00, 5);
    P.sodaCan            = await upsertProduct(client, adminId, PG.beverages, 'Soda (Can)',           'Assorted canned sodas — ask your cashier for available flavors', 45.00, 6);
    P.calamansijuice     = await upsertProduct(client, adminId, PG.beverages, 'Calamansi Juice',      'Refreshing juice from fresh Philippine calamansi',             65.00, 7);

    console.log(`  ✓ Products: ${Object.keys(P).length}`);

    // ── Product ↔ Modifier Group links ────────────────────────────────────────
    // Burgers
    await linkProductModifier(client, P.classicBurger,  MG.size,  0);
    await linkProductModifier(client, P.classicBurger,  MG.addons,1);
    await linkProductModifier(client, P.classicBurger,  MG.sauce, 2);

    await linkProductModifier(client, P.cheeseBurger,   MG.size,  0);
    await linkProductModifier(client, P.cheeseBurger,   MG.addons,1);
    await linkProductModifier(client, P.cheeseBurger,   MG.sauce, 2);

    await linkProductModifier(client, P.bbqBaconBurger, MG.size,  0);
    await linkProductModifier(client, P.bbqBaconBurger, MG.addons,1);
    await linkProductModifier(client, P.bbqBaconBurger, MG.sauce, 2);

    await linkProductModifier(client, P.doublePatty, MG.size,  0);
    await linkProductModifier(client, P.doublePatty, MG.sauce, 1);

    await linkProductModifier(client, P.spicyBurger, MG.size,  0);
    await linkProductModifier(client, P.spicyBurger, MG.spice, 1);
    await linkProductModifier(client, P.spicyBurger, MG.sauce, 2);

    await linkProductModifier(client, P.mushroomBurger,      MG.size,  0);
    await linkProductModifier(client, P.mushroomBurger,      MG.addons,1);
    await linkProductModifier(client, P.mushroomBurger,      MG.sauce, 2);
    await linkProductModifier(client, P.fishBurger,          MG.size,  0);
    await linkProductModifier(client, P.fishBurger,          MG.sauce, 1);
    await linkProductModifier(client, P.crispyChickenBurger, MG.size,  0);
    await linkProductModifier(client, P.crispyChickenBurger, MG.addons,1);
    await linkProductModifier(client, P.crispyChickenBurger, MG.sauce, 2);

    // Chicken
    await linkProductModifier(client, P.friedChicken,        MG.size,  0);
    await linkProductModifier(client, P.friedChicken,        MG.spice, 1);
    await linkProductModifier(client, P.grilledChicken,      MG.spice, 0);
    await linkProductModifier(client, P.grilledChicken,      MG.sauce, 1);
    await linkProductModifier(client, P.chickenSandwich,     MG.addons,0);
    await linkProductModifier(client, P.chickenSandwich,     MG.sauce, 1);
    await linkProductModifier(client, P.chickenWings,        MG.size,  0);
    await linkProductModifier(client, P.chickenWings,        MG.spice, 1);
    await linkProductModifier(client, P.chickenWings,        MG.sauce, 2);
    await linkProductModifier(client, P.spicyChickenSandwich,MG.spice, 0);
    await linkProductModifier(client, P.spicyChickenSandwich,MG.addons,1);
    await linkProductModifier(client, P.spicyChickenSandwich,MG.sauce, 2);
    await linkProductModifier(client, P.chickenStrips,       MG.spice, 0);
    await linkProductModifier(client, P.chickenStrips,       MG.sauce, 1);

    // Rice Meals
    await linkProductModifier(client, P.chickenRiceBowl, MG.spice,  0);
    await linkProductModifier(client, P.chickenRiceBowl, MG.addons, 1);
    await linkProductModifier(client, P.beefRiceBowl,    MG.addons, 0);
    await linkProductModifier(client, P.sisig,           MG.spice,  0);
    await linkProductModifier(client, P.tapsilog,        MG.spice,  0);
    await linkProductModifier(client, P.bangusRice,      MG.spice,  0);

    // Sides
    await linkProductModifier(client, P.frenchFries, MG.size,  0);
    await linkProductModifier(client, P.frenchFries, MG.sauce, 1);
    await linkProductModifier(client, P.onionRings,  MG.sauce, 0);
    await linkProductModifier(client, P.mozSticks,   MG.sauce, 0);
    await linkProductModifier(client, P.loadedFries, MG.size,  0);
    await linkProductModifier(client, P.loadedFries, MG.sauce, 1);

    // Beverages
    await linkProductModifier(client, P.lemonade,           MG.size,       0);
    await linkProductModifier(client, P.lemonade,           MG.sugarLevel, 1);
    await linkProductModifier(client, P.icedTea,            MG.size,       0);
    await linkProductModifier(client, P.icedTea,            MG.sugarLevel, 1);
    await linkProductModifier(client, P.coldCoffee,         MG.size,       0);
    await linkProductModifier(client, P.coldCoffee,         MG.sugarLevel, 1);
    await linkProductModifier(client, P.mangoShake,         MG.size,       0);
    await linkProductModifier(client, P.mangoShake,         MG.sugarLevel, 1);
    await linkProductModifier(client, P.chocolateMilkshake, MG.size,       0);
    await linkProductModifier(client, P.chocolateMilkshake, MG.sugarLevel, 1);
    await linkProductModifier(client, P.calamansijuice,     MG.size,       0);
    await linkProductModifier(client, P.calamansijuice,     MG.sugarLevel, 1);

    console.log('  ✓ Product–modifier-group links seeded');

    await client.query('COMMIT');
    console.log('\nKiosk catalog seed completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed failed:', err.message);
    throw err;
  } finally {
    client.release();
  }
}

seed()
  .then(() => process.exit(0))
  .catch(() => process.exit(1))
  .finally(() => pool.end());
