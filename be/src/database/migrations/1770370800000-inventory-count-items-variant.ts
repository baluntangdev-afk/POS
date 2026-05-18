import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountItemsVariant1770370800000 implements MigrationInterface {
  name = 'InventoryCountItemsVariant1770370800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "inventory_count_items" ADD "variant_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD CONSTRAINT "FK_inventory_count_items_variant" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" DROP CONSTRAINT "FK_inventory_count_items_variant"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_count_items" DROP COLUMN "variant_id"`);
  }
}
