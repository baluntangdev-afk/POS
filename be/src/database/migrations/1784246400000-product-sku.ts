import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * ERP back-office integration: products gain a `sku` column mapping to the
 * ERP material code. Unique among live (non-deleted) rows so ERP menu sync
 * can upsert by SKU.
 */
export class ProductSku1784246400000 implements MigrationInterface {
  name = 'ProductSku1784246400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "products" ADD COLUMN "sku" character varying(140)`);
    await queryRunner.query(
      `CREATE UNIQUE INDEX "UQ_products_sku" ON "products" ("sku") WHERE "sku" IS NOT NULL AND "deleted_at" IS NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "UQ_products_sku"`);
    await queryRunner.query(`ALTER TABLE "products" DROP COLUMN "sku"`);
  }
}
