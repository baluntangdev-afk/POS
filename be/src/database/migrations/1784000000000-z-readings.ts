import { MigrationInterface, QueryRunner } from 'typeorm';

export class ZReadings1784000000000 implements MigrationInterface {
  name = 'ZReadings1784000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE SEQUENCE "z_readings_z_counter_seq" START 1`);

    await queryRunner.query(`
      CREATE TABLE "z_readings" (
        "id" uuid NOT NULL,
        "z_counter" integer NOT NULL DEFAULT nextval('z_readings_z_counter_seq'),
        "period_start" timestamp,
        "period_end" timestamp,
        "generated_at" timestamp NOT NULL DEFAULT now(),
        "closed_by" integer NOT NULL,
        "authorized_by" integer NOT NULL,
        "beginning_balance" numeric(14,2) NOT NULL,
        "ending_balance" numeric(14,2) NOT NULL,
        "snapshot" jsonb NOT NULL,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now(),
        CONSTRAINT "PK_z_readings" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "z_readings"
        ADD CONSTRAINT "FK_z_readings_closed_by"
        FOREIGN KEY ("closed_by") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      ALTER TABLE "z_readings"
        ADD CONSTRAINT "FK_z_readings_authorized_by"
        FOREIGN KEY ("authorized_by") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "idx_z_readings_z_counter" ON "z_readings" ("z_counter")
    `);

    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD COLUMN "done_z_reading" boolean NOT NULL DEFAULT false,
        ADD COLUMN "z_reading_id" uuid
    `);
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        ADD CONSTRAINT "FK_sales_orders_z_reading"
        FOREIGN KEY ("z_reading_id") REFERENCES "z_readings"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      CREATE INDEX "idx_sales_orders_z_reading_id" ON "sales_orders" ("z_reading_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "idx_sales_orders_z_reading_id"`);
    await queryRunner.query(
      `ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_z_reading"`,
    );
    await queryRunner.query(`
      ALTER TABLE "sales_orders"
        DROP COLUMN "z_reading_id",
        DROP COLUMN "done_z_reading"
    `);

    await queryRunner.query(`DROP INDEX "idx_z_readings_z_counter"`);
    await queryRunner.query(
      `ALTER TABLE "z_readings" DROP CONSTRAINT "FK_z_readings_authorized_by"`,
    );
    await queryRunner.query(`ALTER TABLE "z_readings" DROP CONSTRAINT "FK_z_readings_closed_by"`);
    await queryRunner.query(`DROP TABLE "z_readings"`);
    await queryRunner.query(`DROP SEQUENCE "z_readings_z_counter_seq"`);
  }
}
