import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCounts1770367800000 implements MigrationInterface {
  name = 'InventoryCounts1770367800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."inventory_counts_status_enum" AS ENUM('Draft', 'In Progress', 'Completed', 'Cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "inventory_counts" (
        "id" SERIAL NOT NULL,
        "count_date" date NOT NULL DEFAULT now(),
        "status" "public"."inventory_counts_status_enum" NOT NULL DEFAULT 'Draft',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_inventory_counts" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" ADD CONSTRAINT "FK_inventory_counts_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" ADD CONSTRAINT "FK_inventory_counts_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" ADD CONSTRAINT "FK_inventory_counts_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" DROP CONSTRAINT "FK_inventory_counts_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" DROP CONSTRAINT "FK_inventory_counts_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" DROP CONSTRAINT "FK_inventory_counts_created_by"`,
    );
    await queryRunner.query(`DROP TABLE "inventory_counts"`);
    await queryRunner.query(`DROP TYPE "public"."inventory_counts_status_enum"`);
  }
}
