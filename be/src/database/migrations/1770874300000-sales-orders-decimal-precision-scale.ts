import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Alters decimal columns to precision 18, scale 6 in sales_orders, so_items (excluding qty), so_discounts.
 * qty in so_items remains numeric(12,3).
 */
export class SalesOrdersDecimalPrecisionScale1770874300000 implements MigrationInterface {
  name = 'SalesOrdersDecimalPrecisionScale1770874300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "discount_rate" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "tax_rate" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "discount_amount" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "tax_amount" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "total_amount" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "final_total_amount" TYPE numeric(18,6)`,
    );

    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "unit_price" TYPE numeric(18,6)`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_discount_rate" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_discounted_price" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "vat_exclusive_amount" TYPE numeric(18,6)`,
    );
    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "vat_amount" TYPE numeric(18,6)`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_subtotal" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_total_amount" TYPE numeric(18,6)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_paid_amount" TYPE numeric(18,6)`,
    );

    await queryRunner.query(
      `ALTER TABLE "so_discounts" ALTER COLUMN "applied_amount" TYPE numeric(18,6)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "discount_rate" TYPE numeric(5,2)`,
    );
    await queryRunner.query(`ALTER TABLE "sales_orders" ALTER COLUMN "tax_rate" TYPE numeric(5,2)`);
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "discount_amount" TYPE numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "tax_amount" TYPE numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "total_amount" TYPE numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "final_total_amount" TYPE numeric(12,2)`,
    );

    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "unit_price" TYPE numeric(12,2)`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_discount_rate" TYPE numeric(5,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_discounted_price" TYPE numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "vat_exclusive_amount" TYPE numeric(12,2)`,
    );
    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "vat_amount" TYPE numeric(12,2)`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_subtotal" TYPE numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_total_amount" TYPE numeric(12,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ALTER COLUMN "item_paid_amount" TYPE numeric(12,2)`,
    );

    await queryRunner.query(
      `ALTER TABLE "so_discounts" ALTER COLUMN "applied_amount" TYPE numeric(12,2)`,
    );
  }
}
