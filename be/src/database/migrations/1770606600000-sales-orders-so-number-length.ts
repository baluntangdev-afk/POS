import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Increases sales_orders.so_number column length from 12 to 20.
 */
export class SalesOrdersSoNumberLength1770606600000 implements MigrationInterface {
  name = 'SalesOrdersSoNumberLength1770606600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "so_number" TYPE character varying(20)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ALTER COLUMN "so_number" TYPE character varying(12)`,
    );
  }
}
