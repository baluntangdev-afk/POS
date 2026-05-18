import { MigrationInterface, QueryRunner } from 'typeorm';

export class ModifierOptionsImageUrlBytea1770605800000 implements MigrationInterface {
  name = 'ModifierOptionsImageUrlBytea1770605800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "modifier_options" ADD COLUMN "image_url" bytea`);
    await queryRunner.query(
      `COMMENT ON COLUMN "modifier_options"."image_url" IS 'Path to product image'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "modifier_options" DROP COLUMN "image_url"`);
  }
}
