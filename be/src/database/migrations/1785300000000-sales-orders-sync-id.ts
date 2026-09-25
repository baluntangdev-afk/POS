import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * `sales_orders.sync_id` — a stable positive integer per sale, sent as
 * `local_id` to the orders service's `POST /merchant/transactions/sync`,
 * whose contract (shared with the mobile app's SQLite autoincrement ids)
 * rejects anything but a positive integer. The UUID primary key stays the
 * kiosk's internal id.
 *
 * Existing rows are numbered in UUIDv7 (i.e. creation) order so the backlog
 * drains oldest-first; new rows take the next sequence value.
 */
export class SalesOrdersSyncId1785300000000 implements MigrationInterface {
  name = 'SalesOrdersSyncId1785300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE SEQUENCE IF NOT EXISTS "sales_orders_sync_id_seq"`);
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD COLUMN IF NOT EXISTS "sync_id" integer`,
    );
    await queryRunner.query(
      `UPDATE "sales_orders" so
          SET "sync_id" = numbered.rn
         FROM (SELECT "id", ROW_NUMBER() OVER (ORDER BY "id" ASC) AS rn FROM "sales_orders") numbered
        WHERE so."id" = numbered."id" AND so."sync_id" IS NULL`,
    );
    await queryRunner.query(
      `SELECT setval('sales_orders_sync_id_seq', COALESCE((SELECT MAX("sync_id") FROM "sales_orders"), 0) + 1, false)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "sync_id" SET DEFAULT nextval('sales_orders_sync_id_seq')`,
    );
    await queryRunner.query(`ALTER TABLE "sales_orders" ALTER COLUMN "sync_id" SET NOT NULL`);
    await queryRunner.query(
      `ALTER SEQUENCE "sales_orders_sync_id_seq" OWNED BY "sales_orders"."sync_id"`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS "UQ_sales_orders_sync_id" ON "sales_orders" ("sync_id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_sales_orders_sync_id"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN IF EXISTS "sync_id"`);
    await queryRunner.query(`DROP SEQUENCE IF EXISTS "sales_orders_sync_id_seq"`);
  }
}
