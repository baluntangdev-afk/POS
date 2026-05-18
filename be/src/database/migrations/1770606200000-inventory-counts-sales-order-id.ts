import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountsSalesOrderId1770606200000 implements MigrationInterface {
  name = 'InventoryCountsSalesOrderId1770606200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "inventory_counts" ADD "sales_order_id" uuid`);
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" ADD CONSTRAINT "FK_inventory_counts_sales_order" FOREIGN KEY ("sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" DROP CONSTRAINT "FK_inventory_counts_sales_order"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_counts" DROP COLUMN "sales_order_id"`);
  }
}
