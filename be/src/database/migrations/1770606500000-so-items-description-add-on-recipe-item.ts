import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds to so_items:
 * - description: Product summary (e.g., 1 PC CHICKENJOY)
 * - add_on: Whether line is an add-on (inventory snapshot)
 * - recipe_item_id: FK to recipe_items(id), NULL if not add-on
 */
export class SoItemsDescriptionAddOnRecipeItem1770606500000 implements MigrationInterface {
  name = 'SoItemsDescriptionAddOnRecipeItem1770606500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD "description" character varying(255) NOT NULL DEFAULT ''`,
    );
    await queryRunner.query(`ALTER TABLE "so_items" ADD "add_on" boolean NOT NULL DEFAULT false`);
    await queryRunner.query(`ALTER TABLE "so_items" ADD "recipe_item_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_recipe_item_id" FOREIGN KEY ("recipe_item_id") REFERENCES "recipe_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_recipe_item_id"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "recipe_item_id"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "add_on"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "description"`);
  }
}
