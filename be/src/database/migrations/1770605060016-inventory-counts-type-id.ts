import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountsTypeId1770605060016 implements MigrationInterface {
  name = 'InventoryCountsTypeId1770605060016';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "inventory_counts" ADD "type_id" integer`);
    await queryRunner.query(`ALTER TABLE "inventory_counts" ALTER COLUMN "type_id" SET NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" ADD CONSTRAINT "FK_inventory_counts_type_id" FOREIGN KEY ("type_id") REFERENCES "inventory_count_types"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_counts" DROP CONSTRAINT "FK_inventory_counts_type_id"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_counts" DROP COLUMN "type_id"`);
  }
}
