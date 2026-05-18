import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountItemsSoItemId1770606800000 implements MigrationInterface {
  name = 'InventoryCountItemsSoItemId1770606800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "inventory_count_items" ADD "so_item_id" uuid`);
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "FK_inventory_count_items_so_item" FOREIGN KEY ("so_item_id") REFERENCES "so_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "FK_inventory_count_items_so_item"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_count_items" DROP COLUMN "so_item_id"`);
  }
}
