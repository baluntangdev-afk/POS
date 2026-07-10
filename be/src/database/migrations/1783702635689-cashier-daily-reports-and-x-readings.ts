import { MigrationInterface, QueryRunner } from 'typeorm';

export class CashierDailyReportsAndXReadings1783702635689 implements MigrationInterface {
  name = 'CashierDailyReportsAndXReadings1783702635689';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "cashier_daily_reports" (
        "id" uuid NOT NULL,
        "cashier_id" integer NOT NULL,
        "period_start" timestamp,
        "period_end" timestamp,
        "generated_at" timestamp NOT NULL DEFAULT now(),
        "snapshot" jsonb NOT NULL,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now(),
        CONSTRAINT "PK_cashier_daily_reports" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "cashier_daily_reports"
        ADD CONSTRAINT "FK_cashier_daily_reports_cashier"
        FOREIGN KEY ("cashier_id") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_cashier_daily_reports_cashier_id" ON "cashier_daily_reports" ("cashier_id")
    `);

    await queryRunner.query(`
      CREATE TABLE "cashier_x_readings" (
        "id" uuid NOT NULL,
        "cashier_id" integer NOT NULL,
        "period_start" timestamp,
        "period_end" timestamp,
        "generated_at" timestamp NOT NULL DEFAULT now(),
        "snapshot" jsonb NOT NULL,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now(),
        CONSTRAINT "PK_cashier_x_readings" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "cashier_x_readings"
        ADD CONSTRAINT "FK_cashier_x_readings_cashier"
        FOREIGN KEY ("cashier_id") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_cashier_x_readings_cashier_id" ON "cashier_x_readings" ("cashier_id")
    `);

    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD COLUMN "daily_report_id" uuid,
        ADD COLUMN "x_reading_id" uuid
    `);
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD CONSTRAINT "FK_sales_orders_daily_report"
        FOREIGN KEY ("daily_report_id") REFERENCES "cashier_daily_reports"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD CONSTRAINT "FK_sales_orders_x_reading"
        FOREIGN KEY ("x_reading_id") REFERENCES "cashier_x_readings"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_sales_orders_daily_report_id" ON "sales_orders" ("daily_report_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_sales_orders_x_reading_id" ON "sales_orders" ("x_reading_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "idx_sales_orders_x_reading_id"`);
    await queryRunner.query(`DROP INDEX "idx_sales_orders_daily_report_id"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_x_reading"`);
    await queryRunner.query(`ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_daily_report"`);
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        DROP COLUMN "x_reading_id",
        DROP COLUMN "daily_report_id"
    `);

    await queryRunner.query(`DROP INDEX "idx_cashier_x_readings_cashier_id"`);
    await queryRunner.query(`ALTER TABLE "cashier_x_readings" DROP CONSTRAINT "FK_cashier_x_readings_cashier"`);
    await queryRunner.query(`DROP TABLE "cashier_x_readings"`);

    await queryRunner.query(`DROP INDEX "idx_cashier_daily_reports_cashier_id"`);
    await queryRunner.query(`ALTER TABLE "cashier_daily_reports" DROP CONSTRAINT "FK_cashier_daily_reports_cashier"`);
    await queryRunner.query(`DROP TABLE "cashier_daily_reports"`);
  }
}
