import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrdersDoneDailyReportAndXReading1783692405858 implements MigrationInterface {
  name = 'SalesOrdersDoneDailyReportAndXReading1783692405858';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD COLUMN "done_daily_report" boolean NOT NULL DEFAULT false,
        ADD COLUMN "done_x_reading" boolean NOT NULL DEFAULT false
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        DROP COLUMN IF EXISTS "done_daily_report",
        DROP COLUMN IF EXISTS "done_x_reading"
    `);
  }
}
