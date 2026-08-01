import { MigrationInterface, QueryRunner } from 'typeorm';

export class AugmentTablesForKioskCatalog1779582000000 implements MigrationInterface {
  name = 'AugmentTablesForKioskCatalog1779582000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // ── products ──────────────────────────────────────────────────────────────
    // Replace bytea image_url with a plain text URL column
    await queryRunner.query(`ALTER TABLE "products" DROP COLUMN IF EXISTS "image_url"`);
    await queryRunner.query(`ALTER TABLE "products" ADD COLUMN "image_url" TEXT`);
    await queryRunner.query(
      `ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "price" NUMERIC(10,2) NOT NULL DEFAULT 0.00`,
    );
    await queryRunner.query(
      `ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "category" VARCHAR(100)`,
    );
    await queryRunner.query(
      `ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "is_available" BOOLEAN NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "sort_order" INT NOT NULL DEFAULT 0`,
    );

    // ── modifier_groups ───────────────────────────────────────────────────────
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" ADD COLUMN IF NOT EXISTS "description" TEXT`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" ADD COLUMN IF NOT EXISTS "selection_type" VARCHAR(10) NOT NULL DEFAULT 'single'`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" ADD COLUMN IF NOT EXISTS "is_required" BOOLEAN NOT NULL DEFAULT false`,
    );

    // ── modifier_options ──────────────────────────────────────────────────────
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD COLUMN IF NOT EXISTS "is_available" BOOLEAN NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD COLUMN IF NOT EXISTS "sort_order" INT NOT NULL DEFAULT 0`,
    );

    // ── product_modifier_groups junction ──────────────────────────────────────
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "product_modifier_groups" (
        "product_id"        INTEGER NOT NULL,
        "modifier_group_id" INTEGER NOT NULL,
        "sort_order"        INT     NOT NULL DEFAULT 0,
        CONSTRAINT "PK_product_modifier_groups"
          PRIMARY KEY ("product_id", "modifier_group_id"),
        CONSTRAINT "FK_pmg_product"
          FOREIGN KEY ("product_id")
            REFERENCES "products"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_pmg_modifier_group"
          FOREIGN KEY ("modifier_group_id")
            REFERENCES "modifier_groups"("id") ON DELETE CASCADE
      )
    `);

    // ── indexes ───────────────────────────────────────────────────────────────
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_products_category"     ON "products"("category")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_products_is_available" ON "products"("is_available")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_pmg_product_id"        ON "product_modifier_groups"("product_id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_pmg_product_id"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_products_is_available"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_products_category"`);
    await queryRunner.query(`DROP TABLE  IF EXISTS "product_modifier_groups"`);
    await queryRunner.query(`ALTER TABLE "modifier_options"  DROP COLUMN IF EXISTS "sort_order"`);
    await queryRunner.query(`ALTER TABLE "modifier_options"  DROP COLUMN IF EXISTS "is_available"`);
    await queryRunner.query(`ALTER TABLE "modifier_groups"   DROP COLUMN IF EXISTS "is_required"`);
    await queryRunner.query(`ALTER TABLE "modifier_groups"   DROP COLUMN IF EXISTS "selection_type"`);
    await queryRunner.query(`ALTER TABLE "modifier_groups"   DROP COLUMN IF EXISTS "description"`);
    await queryRunner.query(`ALTER TABLE "products"          DROP COLUMN IF EXISTS "sort_order"`);
    await queryRunner.query(`ALTER TABLE "products"          DROP COLUMN IF EXISTS "is_available"`);
    await queryRunner.query(`ALTER TABLE "products"          DROP COLUMN IF EXISTS "category"`);
    await queryRunner.query(`ALTER TABLE "products"          DROP COLUMN IF EXISTS "price"`);
    await queryRunner.query(`ALTER TABLE "products"          DROP COLUMN IF EXISTS "image_url"`);
    await queryRunner.query(`ALTER TABLE "products"          ADD  COLUMN "image_url" BYTEA`);
  }
}
