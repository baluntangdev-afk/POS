import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersTotalAmount1770606300000 implements MigrationInterface {
  name = 'SalesOrdersTotalAmount1770606300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD "total_amount" numeric(12,2) NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN "total_amount"`);
  }
}
