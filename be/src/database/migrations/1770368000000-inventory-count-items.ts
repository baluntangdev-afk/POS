import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountItems1770368000000 implements MigrationInterface {
  name = 'InventoryCountItems1770368000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "inventory_count_items" (
        "id" SERIAL NOT NULL,
        "inventory_count_id" integer NOT NULL,
        "material_id" integer,
        "system_qty" numeric(12,3) NOT NULL,
        "counted_qty" numeric(12,3) NOT NULL,
        "variance_qty" numeric(12,3) NOT NULL,
        "unit_id" integer NOT NULL,
        CONSTRAINT "PK_inventory_count_items" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "FK_inventory_count_items_inventory_count" FOREIGN KEY ("inventory_count_id") REFERENCES "inventory_counts"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "FK_inventory_count_items_material" FOREIGN KEY ("material_id") REFERENCES "materials"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "FK_inventory_count_items_unit" FOREIGN KEY ("unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "FK_inventory_count_items_unit"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "FK_inventory_count_items_material"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "FK_inventory_count_items_inventory_count"`,
    );
    await queryRunner.query(`DROP TABLE "inventory_count_items"`);
  }
}
