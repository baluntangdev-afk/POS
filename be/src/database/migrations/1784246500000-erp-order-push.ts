import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * ERP back-office integration: retry queue for pushing confirmed sales orders
 * to the ERP (one row per order, unique on so_id so retries never duplicate).
 */
export class ErpOrderPush1784246500000 implements MigrationInterface {
  name = 'ErpOrderPush1784246500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "erp_order_push" (
        "id" SERIAL NOT NULL,
        "so_id" uuid NOT NULL,
        "status" character varying(20) NOT NULL DEFAULT 'Pending',
        "attempts" integer NOT NULL DEFAULT 0,
        "last_error" text,
        "last_attempt_at" TIMESTAMP,
        "sent_at" TIMESTAMP,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_erp_order_push" PRIMARY KEY ("id"),
        CONSTRAINT "FK_erp_order_push_so" FOREIGN KEY ("so_id") REFERENCES "sales_orders"("id")
      )
    `);
    await queryRunner.query(
      `CREATE UNIQUE INDEX "UQ_erp_order_push_so_id" ON "erp_order_push" ("so_id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "erp_order_push"`);
  }
}
