import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryStocksVariant1770370900000 implements MigrationInterface {
  name = 'InventoryStocksVariant1770370900000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "inventory_stocks" ADD "variant_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" ADD CONSTRAINT "FK_inventory_stocks_variant" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "inventory_stocks" DROP CONSTRAINT "FK_inventory_stocks_variant"`,
    );
    await queryRunner.query(`ALTER TABLE "inventory_stocks" DROP COLUMN "variant_id"`);
  }
}
