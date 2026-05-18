import { MigrationInterface, QueryRunner } from 'typeorm';

export class RecipeItemsExtra1770605700000 implements MigrationInterface {
  name = 'RecipeItemsExtra1770605700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD COLUMN "extra" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `COMMENT ON COLUMN "recipe_items"."extra" IS 'Add-on to the base meal or part of the staple ingredients'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "recipe_items" DROP COLUMN "extra"`);
  }
}
