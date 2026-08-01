import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProductVariantsPrice1779583600000 implements MigrationInterface {
  name = 'ProductVariantsPrice1779583600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "product_variants" ADD COLUMN "price" numeric(10,2) NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "product_variants" DROP COLUMN "price"`,
    );
  }
}
