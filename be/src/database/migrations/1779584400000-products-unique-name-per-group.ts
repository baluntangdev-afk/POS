import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Product names are unique PER CATEGORY (product group), not globally. The CSV
 * importer legitimately carries the same product name in two categories
 * (e.g. "Avocado Premium" in both Smoothies and Salads), which the old global
 * `UQ_products_name` constraint rejected mid-import.
 *
 * Replaces the global unique constraint with a partial unique index on
 * (group_id, name) limited to live rows (`deleted_at IS NULL`) so a soft-deleted
 * product never blocks re-inserting/undeleting a same-named one — the CSV seeder
 * relies on this for idempotent re-runs.
 */
export class ProductsUniqueNamePerGroup1779584400000 implements MigrationInterface {
  name = 'ProductsUniqueNamePerGroup1779584400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "products" DROP CONSTRAINT "UQ_products_name"`);
    await queryRunner.query(
      `CREATE UNIQUE INDEX "UQ_products_group_name" ON "products" ("group_id", "name") WHERE "deleted_at" IS NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "public"."UQ_products_group_name"`);
    await queryRunner.query(
      `ALTER TABLE "products" ADD CONSTRAINT "UQ_products_name" UNIQUE ("name")`,
    );
  }
}
