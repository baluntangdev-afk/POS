import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersTaxRate1770605300000 implements MigrationInterface {
  name = 'SalesOrdersTaxRate1770605300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD "tax_rate" numeric(5,2) NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN "tax_rate"`);
  }
}
