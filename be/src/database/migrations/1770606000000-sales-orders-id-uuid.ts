import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Changes sales_orders.id from integer to UUID (for UUID v7 generated in application).
 * Assumes no existing data; drops and re-adds columns.
 */
export class SalesOrdersIdUuid1770606000000 implements MigrationInterface {
  name = 'SalesOrdersIdUuid1770606000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_so_id"`);
    await queryRunner.query(
      `ALTER TABLE "so_discounts" DROP CONSTRAINT "FK_so_discounts_sales_order_id"`,
    );
    await queryRunner.query(`ALTER TABLE "payments" DROP CONSTRAINT "FK_payments_sales_order"`);
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_original_sales_order"`,
    );

    await queryRunner.query(`ALTER TABLE "sales_orders" DROP CONSTRAINT "PK_sales_orders"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN "id"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" ADD "id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD CONSTRAINT "PK_sales_orders" PRIMARY KEY ("id")`,
    );

    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "so_id"`);
    await queryRunner.query(`ALTER TABLE "so_items" ADD "so_id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_so_id" FOREIGN KEY ("so_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );

    await queryRunner.query(`ALTER TABLE "so_discounts" DROP COLUMN "sales_order_id"`);
    await queryRunner.query(`ALTER TABLE "so_discounts" ADD "sales_order_id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "FK_so_discounts_sales_order_id" FOREIGN KEY ("sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );

    await queryRunner.query(`ALTER TABLE "payments" DROP COLUMN "sales_order_id"`);
    await queryRunner.query(`ALTER TABLE "payments" ADD "sales_order_id" uuid`);
    await queryRunner.query(
      `ALTER TABLE "payments" ADD CONSTRAINT "FK_payments_sales_order" FOREIGN KEY ("sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );

    await queryRunner.query(`ALTER TABLE "refunds" DROP COLUMN "original_sales_order_id"`);
    await queryRunner.query(`ALTER TABLE "refunds" ADD "original_sales_order_id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_original_sales_order" FOREIGN KEY ("original_sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  /**
   * Downgrade not supported: reverting UUID to integer would require a stored mapping.
   */
  public down(): Promise<void> {
    return Promise.resolve();
  }
}
