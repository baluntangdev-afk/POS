import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsOptionalProductVariant1779582300000 implements MigrationInterface {
  name = 'SoItemsOptionalProductVariant1779582300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "product_variant_id" DROP NOT NULL`);
    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "recipe_id" DROP NOT NULL`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "recipe_id" SET NOT NULL`);
    await queryRunner.query(`ALTER TABLE "so_items" ALTER COLUMN "product_variant_id" SET NOT NULL`);
  }
}
