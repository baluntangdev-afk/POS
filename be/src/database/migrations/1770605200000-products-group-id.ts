import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProductsGroupId1770605200000 implements MigrationInterface {
  name = 'ProductsGroupId1770605200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "products" ADD "group_id" integer`);
    await queryRunner.query(`ALTER TABLE "products" ALTER COLUMN "group_id" SET NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "products" ADD CONSTRAINT "FK_products_product_group" FOREIGN KEY ("group_id") REFERENCES "product_groups"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "products" DROP CONSTRAINT "FK_products_product_group"`);
    await queryRunner.query(`ALTER TABLE "products" DROP COLUMN "group_id"`);
  }
}
