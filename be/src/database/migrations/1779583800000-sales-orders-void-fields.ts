import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersVoidFields1779583800000 implements MigrationInterface {
  name = 'SalesOrdersVoidFields1779583800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD COLUMN "void_reason" VARCHAR(500) NULL,
        ADD COLUMN "voided_by" INT NULL REFERENCES "users"("id"),
        ADD COLUMN "voided_at" TIMESTAMP NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        DROP COLUMN IF EXISTS "void_reason",
        DROP COLUMN IF EXISTS "voided_by",
        DROP COLUMN IF EXISTS "voided_at"
    `);
  }
}
