import { MigrationInterface, QueryRunner } from 'typeorm';

export class ModifierOptionsRecipeItemId1770605900000 implements MigrationInterface {
  name = 'ModifierOptionsRecipeItemId1770605900000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "modifier_options" ADD COLUMN "recipe_item_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD CONSTRAINT "FK_modifier_options_recipe_item" FOREIGN KEY ("recipe_item_id") REFERENCES "recipe_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "modifier_options" DROP CONSTRAINT "FK_modifier_options_recipe_item"`,
    );
    await queryRunner.query(`ALTER TABLE "modifier_options" DROP COLUMN "recipe_item_id"`);
  }
}
