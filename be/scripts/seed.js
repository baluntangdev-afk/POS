'use strict';

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'postgres',
  database: process.env.POSTGRES_DB || 'pos_db',
});

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Truncate in safe dependency order
    console.log('Truncating catalog tables...');
    await client.query(`
      TRUNCATE TABLE
        catalog_product_modifier_groups,
        catalog_modifiers,
        catalog_modifier_groups,
        catalog_products,
        catalog_categories
      RESTART IDENTITY CASCADE
    `);
    console.log('  ✓ Tables truncated');

    // Categories
    const categoriesResult = await client.query(`
      INSERT INTO catalog_categories (id, name, sort_order) VALUES
        ('10000000-0000-0000-0000-000000000001', 'Burgers', 0),
        ('10000000-0000-0000-0000-000000000002', 'Drinks',  1),
        ('10000000-0000-0000-0000-000000000003', 'Sides',   2)
      ON CONFLICT (name) DO NOTHING
      RETURNING id
    `);
    console.log(`  ✓ Categories: ${categoriesResult.rowCount} inserted`);

    // Modifier groups
    const modGroupsResult = await client.query(`
      INSERT INTO catalog_modifier_groups (id, name, selection_type, is_required, min_selections, max_selections) VALUES
        ('30000000-0000-0000-0000-000000000001', 'Size',    'single',   true,  1, 1),
        ('30000000-0000-0000-0000-000000000002', 'Add-ons', 'multiple', false, 0, 5),
        ('30000000-0000-0000-0000-000000000003', 'Sauce',   'single',   false, 0, 1)
      ON CONFLICT (name) DO NOTHING
      RETURNING id
    `);
    console.log(`  ✓ Modifier groups: ${modGroupsResult.rowCount} inserted`);

    // Modifiers
    const modifiersResult = await client.query(`
      INSERT INTO catalog_modifiers (id, modifier_group_id, name, price_adjustment, sort_order) VALUES
        ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'Regular',       0.00, 0),
        ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'Large',         25.00, 1),
        ('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 'Extra Large',   45.00, 2),
        ('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000002', 'Extra Cheese',  15.00, 0),
        ('40000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000002', 'Bacon',         25.00, 1),
        ('40000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000002', 'Avocado',       30.00, 2),
        ('40000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000002', 'Fried Egg',     20.00, 3),
        ('40000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000002', 'Jalapeños',     10.00, 4),
        ('40000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000003', 'Ketchup',        0.00, 0),
        ('40000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000003', 'Mustard',        0.00, 1),
        ('40000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000003', 'Mayo',           0.00, 2),
        ('40000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000003', 'BBQ Sauce',      0.00, 3),
        ('40000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000003', 'Hot Sauce',      0.00, 4)
      ON CONFLICT (modifier_group_id, name) DO NOTHING
      RETURNING id
    `);
    console.log(`  ✓ Modifiers: ${modifiersResult.rowCount} inserted`);

    // Products
    const productsResult = await client.query(`
      INSERT INTO catalog_products (id, category_id, name, price, sort_order) VALUES
        ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Classic Burger',    149.00, 0),
        ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'Cheese Burger',     169.00, 1),
        ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'BBQ Bacon Burger',  199.00, 2),
        ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'Veggie Burger',     139.00, 3),
        ('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'Lemonade',           65.00, 0),
        ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', 'Iced Tea',           55.00, 1),
        ('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', 'Bottled Water',      35.00, 2),
        ('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', 'French Fries',       75.00, 0)
      ON CONFLICT (name) DO NOTHING
      RETURNING id
    `);
    console.log(`  ✓ Products: ${productsResult.rowCount} inserted`);

    // Product-modifier-group links
    const linksResult = await client.query(`
      INSERT INTO catalog_product_modifier_groups (product_id, modifier_group_id, sort_order) VALUES
        ('20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 1),
        ('20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 2),
        ('20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 1),
        ('20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', 2),
        ('20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000002', 1),
        ('20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', 2),
        ('20000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000003', 1),
        ('20000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000001', 0),
        ('20000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000003', 1)
      ON CONFLICT DO NOTHING
      RETURNING product_id
    `);
    console.log(`  ✓ Product-modifier-group links: ${linksResult.rowCount} inserted`);

    await client.query('COMMIT');
    console.log('\nCatalog seed completed successfully.');
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
