import { MigrationInterface, QueryRunner } from 'typeorm';

export class RefundItems1770604414268 implements MigrationInterface {
  name = 'RefundItems1770604414268';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "refund_items" (
        "id" SERIAL NOT NULL,
        "refund_id" integer NOT NULL,
        "sales_order_item_id" integer NOT NULL,
        "quantity" integer NOT NULL,
        "refund_amount" numeric(12,2) NOT NULL,
        "restock_inventory" boolean NOT NULL DEFAULT false,
        CONSTRAINT "PK_refund_items" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_refund_items_refund_id" FOREIGN KEY ("refund_id") REFERENCES "refunds"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_refund_items_sales_order_item_id" FOREIGN KEY ("sales_order_item_id") REFERENCES "so_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_refund_items_sales_order_item_id"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_refund_items_refund_id"`,
    );
    await queryRunner.query(`DROP TABLE "refund_items"`);
  }
}
