import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Changes primary keys to UUID (app-generated UUID v7) for:
 * so_items, payments, so_discounts, inventory_counts, inventory_count_items.
 * Also updates refund_items.sales_order_item_id to uuid.
 * Assumes no existing data.
 */
export class UuidV7SoItemsPaymentsInventory1770606100000 implements MigrationInterface {
  name = 'UuidV7SoItemsPaymentsInventory1770606100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_refund_items_sales_order_item_id"`,
    );
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "PK_so_items"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "id"`);
    await queryRunner.query(`ALTER TABLE "so_items" ADD "id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "PK_so_items" PRIMARY KEY ("id")`,
    );
    await queryRunner.query(`ALTER TABLE "refund_items" DROP COLUMN "sales_order_item_id"`);
    await queryRunner.query(`ALTER TABLE "refund_items" ADD "sales_order_item_id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_refund_items_sales_order_item_id" FOREIGN KEY ("sales_order_item_id") REFERENCES "so_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );

    await queryRunner.query(`ALTER TABLE "payments" DROP CONSTRAINT "PK_payments"`);
    await queryRunner.query(`ALTER TABLE "payments" DROP COLUMN "id"`);
    await queryRunner.query(`ALTER TABLE "payments" ADD "id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "payments" ADD CONSTRAINT "PK_payments" PRIMARY KEY ("id")`,
    );

    await queryRunner.query(`ALTER TABLE "so_discounts" DROP CONSTRAINT "PK_so_discounts"`);
    await queryRunner.query(`ALTER TABLE "so_discounts" DROP COLUMN "id"`);
    await queryRunner.query(`ALTER TABLE "so_discounts" ADD "id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "PK_so_discounts" PRIMARY KEY ("id")`,
    );

    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "FK_inventory_count_items_inventory_count"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_counts" DROP CONSTRAINT "PK_inventory_counts"`);
    await queryRunner.query(`ALTER TABLE "inventory_counts" DROP COLUMN "id"`);
    await queryRunner.query(`ALTER TABLE "inventory_counts" ADD "id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" ADD CONSTRAINT "PK_inventory_counts" PRIMARY KEY ("id")`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_count_items" DROP COLUMN "inventory_count_id"`);
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD "inventory_count_id" uuid NOT NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "FK_inventory_count_items_inventory_count" FOREIGN KEY ("inventory_count_id") REFERENCES "inventory_counts"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "PK_inventory_count_items"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_count_items" DROP COLUMN "id"`);
    await queryRunner.query(`ALTER TABLE "inventory_count_items" ADD "id" uuid NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "PK_inventory_count_items" PRIMARY KEY ("id")`,
    );
  }

  public down(): Promise<void> {
    return Promise.resolve();
  }
}
