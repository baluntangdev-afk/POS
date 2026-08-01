import { MigrationInterface, QueryRunner } from 'typeorm';

export class DropCatalogTables1779582100000 implements MigrationInterface {
  name = 'DropCatalogTables1779582100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX  IF EXISTS "idx_catalog_pmg_product_id"`);
    await queryRunner.query(`DROP INDEX  IF EXISTS "idx_catalog_modifiers_group_id"`);
    await queryRunner.query(`DROP INDEX  IF EXISTS "idx_catalog_products_category_id"`);
    await queryRunner.query(`DROP TABLE  IF EXISTS "catalog_product_modifier_groups"`);
    await queryRunner.query(`DROP TABLE  IF EXISTS "catalog_modifiers"`);
    await queryRunner.query(`DROP TABLE  IF EXISTS "catalog_modifier_groups"`);
    await queryRunner.query(`DROP TABLE  IF EXISTS "catalog_products"`);
    await queryRunner.query(`DROP TABLE  IF EXISTS "catalog_categories"`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Re-create catalog_ tables (structure only – seed data is not restored)
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
        selection_type VARCHAR(10) NOT NULL DEFAULT 'single',
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
  }
}
