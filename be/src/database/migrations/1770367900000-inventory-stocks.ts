import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryStocks1770367900000 implements MigrationInterface {
  name = 'InventoryStocks1770367900000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "inventory_stocks" (
        "id" SERIAL NOT NULL,
        "material_id" integer,
        "quantity_on_hand" numeric(12,3) NOT NULL DEFAULT 0,
        "unit_id" integer NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_inventory_stocks" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" ADD CONSTRAINT "FK_inventory_stocks_material" FOREIGN KEY ("material_id") REFERENCES "materials"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" ADD CONSTRAINT "FK_inventory_stocks_unit" FOREIGN KEY ("unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" ADD CONSTRAINT "FK_inventory_stocks_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" ADD CONSTRAINT "FK_inventory_stocks_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" ADD CONSTRAINT "FK_inventory_stocks_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" DROP CONSTRAINT "FK_inventory_stocks_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" DROP CONSTRAINT "FK_inventory_stocks_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" DROP CONSTRAINT "FK_inventory_stocks_created_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" DROP CONSTRAINT "FK_inventory_stocks_unit"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" DROP CONSTRAINT "FK_inventory_stocks_material"`,
    );
    await queryRunner.query(`DROP TABLE "inventory_stocks"`);
  }
}
