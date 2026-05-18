import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProductGroupsImageUrlBytea1770605600000 implements MigrationInterface {
  name = 'ProductGroupsImageUrlBytea1770605600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "product_groups" ALTER COLUMN "image_url" TYPE bytea USING CASE WHEN "image_url" IS NULL THEN NULL ELSE convert_to("image_url", 'UTF8') END`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "product_groups" ALTER COLUMN "image_url" TYPE character varying(255) USING CASE WHEN "image_url" IS NULL THEN NULL ELSE convert_from("image_url", 'UTF8') END`,
    );
  }
}
