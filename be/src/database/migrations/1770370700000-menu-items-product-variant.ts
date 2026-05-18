import { MigrationInterface, QueryRunner } from 'typeorm';

export class MenuItemsProductVariant1770370700000 implements MigrationInterface {
  name = 'MenuItemsProductVariant1770370700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "menu_items" ADD "product_variant_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "menu_items" ADD CONSTRAINT "FK_menu_items_product_variant" FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "menu_items" DROP CONSTRAINT "FK_menu_items_product_variant"`,
    );
    await queryRunner.query(`ALTER TABLE "menu_items" DROP COLUMN "product_variant_id"`);
  }
}
