import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Sync state for pushing sales/refunds to the external orders service
 * (`POST /merchant/transactions/sync`), which the kiosk app drives.
 *
 * - `sales_orders.store_id` — the merchant (POS terminal Kiosk ID) a sale was
 *   made under, stamped at creation. Only sales stamped with the currently
 *   active Kiosk ID are pushed, so a sale made under a merchant this device
 *   has since been reassigned away from is never sent to the new one.
 * - `sales_orders.synced_at` / `refunds.synced_at` — null until the orders
 *   service accepts the record.
 */
export class TransactionSyncState1785200000000 implements MigrationInterface {
  name = 'TransactionSyncState1785200000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD COLUMN IF NOT EXISTS "store_id" character varying(100)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD COLUMN IF NOT EXISTS "synced_at" TIMESTAMP`,
    );
    await queryRunner.query(`ALTER TABLE "refunds" ADD COLUMN IF NOT EXISTS "synced_at" TIMESTAMP`);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_sales_orders_store_id_synced_at" ON "sales_orders" ("store_id", "synced_at")`,
    );

    // Backfill: every existing sale was made under the (single) terminal's
    // current Kiosk ID, since there was no per-sale merchant before this.
    await queryRunner.query(
      `UPDATE "sales_orders"
          SET "store_id" = (SELECT "kiosk_id" FROM "pos_terminals" ORDER BY "id" ASC LIMIT 1)
        WHERE "store_id" IS NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_sales_orders_store_id_synced_at"`);
    await queryRunner.query(`ALTER TABLE "refunds" DROP COLUMN IF EXISTS "synced_at"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN IF EXISTS "synced_at"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN IF EXISTS "store_id"`);
  }
}
