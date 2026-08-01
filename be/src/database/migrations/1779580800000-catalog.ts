import { MigrationInterface, QueryRunner } from 'typeorm';

export class Catalog1779580800000 implements MigrationInterface {
  name = 'Catalog1779580800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS catalog_categories (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL,
        description TEXT,
        image_url TEXT,
        sort_order INT DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT uq_catalog_categories_name UNIQUE (name)
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS catalog_products (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        category_id UUID REFERENCES catalog_categories(id) ON DELETE SET NULL,
        name VARCHAR(150) NOT NULL,
        description TEXT,
        price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
        image_url TEXT,
        is_available BOOLEAN DEFAULT true,
        sort_order INT DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT uq_catalog_products_name UNIQUE (name)
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS catalog_modifier_groups (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL,
        description TEXT,
        selection_type VARCHAR(10) NOT NULL CHECK (selection_type IN ('single', 'multiple')),
        min_selections INT DEFAULT 0,
        max_selections INT DEFAULT 1,
        is_required BOOLEAN DEFAULT false,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT uq_catalog_modifier_groups_name UNIQUE (name)
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS catalog_modifiers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        modifier_group_id UUID NOT NULL REFERENCES catalog_modifier_groups(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        price_adjustment NUMERIC(10, 2) DEFAULT 0.00,
        is_available BOOLEAN DEFAULT true,
        sort_order INT DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT uq_catalog_modifiers_group_name UNIQUE (modifier_group_id, name)
      )
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS catalog_product_modifier_groups (
        product_id UUID NOT NULL REFERENCES catalog_products(id) ON DELETE CASCADE,
        modifier_group_id UUID NOT NULL REFERENCES catalog_modifier_groups(id) ON DELETE CASCADE,
        sort_order INT DEFAULT 0,
        PRIMARY KEY (product_id, modifier_group_id)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_catalog_products_category_id ON catalog_products(category_id)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_catalog_modifiers_group_id ON catalog_modifiers(modifier_group_id)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_catalog_pmg_product_id ON catalog_product_modifier_groups(product_id)`,
    );

    // ── Seed Data ──────────────────────────────────────────────────────────────

    await queryRunner.query(`
      INSERT INTO catalog_categories (id, name, sort_order) VALUES
        ('10000000-0000-0000-0000-000000000001', 'Burgers', 0),
        ('10000000-0000-0000-0000-000000000002', 'Drinks',  1),
        ('10000000-0000-0000-0000-000000000003', 'Sides',   2)
      ON CONFLICT (name) DO NOTHING
    `);

    await queryRunner.query(`
      INSERT INTO catalog_modifier_groups (id, name, selection_type, is_required, min_selections, max_selections) VALUES
        ('30000000-0000-0000-0000-000000000001', 'Size',    'single',   true,  1, 1),
        ('30000000-0000-0000-0000-000000000002', 'Add-ons', 'multiple', false, 0, 5),
        ('30000000-0000-0000-0000-000000000003', 'Sauce',   'single',   false, 0, 1)
      ON CONFLICT (name) DO NOTHING
    `);

    await queryRunner.query(`
      INSERT INTO catalog_modifiers (id, modifier_group_id, name, price_adjustment, sort_order) VALUES
        ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'Regular',     0.00, 0),
        ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'Large',       1.50, 1),
        ('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 'Extra Large', 2.50, 2),
        ('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000002', 'Extra Cheese',0.75, 0),
        ('40000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000002', 'Bacon',       1.25, 1),
        ('40000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000002', 'Avocado',     1.50, 2),
        ('40000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000002', 'Fried Egg',   1.00, 3),
        ('40000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000002', 'Jalapeños',   0.50, 4),
        ('40000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000003', 'Ketchup',     0.00, 0),
        ('40000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000003', 'Mustard',     0.00, 1),
        ('40000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000003', 'Mayo',        0.00, 2),
        ('40000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000003', 'BBQ Sauce',   0.00, 3),
        ('40000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000003', 'Hot Sauce',   0.00, 4)
      ON CONFLICT (modifier_group_id, name) DO NOTHING
    `);

    await queryRunner.query(`
      INSERT INTO catalog_products (id, category_id, name, price, sort_order) VALUES
        ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Classic Burger',   9.99, 0),
        ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'Cheese Burger',   10.99, 1),
        ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'BBQ Bacon Burger',12.99, 2),
        ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'Veggie Burger',    9.49, 3),
        ('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'Lemonade',         2.99, 0),
        ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', 'Iced Tea',         2.49, 1),
        ('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', 'Bottled Water',    1.49, 2),
        ('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', 'French Fries',     3.49, 0)
      ON CONFLICT (name) DO NOTHING
    `);

    await queryRunner.query(`
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
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS idx_catalog_pmg_product_id`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_catalog_modifiers_group_id`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_catalog_products_category_id`);
    await queryRunner.query(`DROP TABLE IF EXISTS catalog_product_modifier_groups`);
    await queryRunner.query(`DROP TABLE IF EXISTS catalog_modifiers`);
    await queryRunner.query(`DROP TABLE IF EXISTS catalog_modifier_groups`);
    await queryRunner.query(`DROP TABLE IF EXISTS catalog_products`);
    await queryRunner.query(`DROP TABLE IF EXISTS catalog_categories`);
  }
}
