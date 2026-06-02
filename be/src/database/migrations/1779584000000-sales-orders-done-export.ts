import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersDoneExport1779584000000 implements MigrationInterface {
  name = 'SalesOrdersDoneExport1779584000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD COLUMN "done_export" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP COLUMN "done_export"`);
  }
}
