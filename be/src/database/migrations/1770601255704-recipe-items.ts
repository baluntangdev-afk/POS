import { MigrationInterface, QueryRunner } from 'typeorm';

export class RecipeItems1770601255704 implements MigrationInterface {
  name = 'RecipeItems1770601255704';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "recipe_items" (
        "id" SERIAL NOT NULL,
        "recipe_id" integer NOT NULL,
        "material_id" integer NOT NULL,
        "quantity" numeric(12,3) NOT NULL,
        "unit_id" integer NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_recipe_items" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD CONSTRAINT "FK_recipe_items_recipe" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD CONSTRAINT "FK_recipe_items_material" FOREIGN KEY ("material_id") REFERENCES "materials"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD CONSTRAINT "FK_recipe_items_unit" FOREIGN KEY ("unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD CONSTRAINT "FK_recipe_items_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD CONSTRAINT "FK_recipe_items_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" ADD CONSTRAINT "FK_recipe_items_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "recipe_items" DROP CONSTRAINT "FK_recipe_items_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" DROP CONSTRAINT "FK_recipe_items_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_items" DROP CONSTRAINT "FK_recipe_items_created_by"`,
    );
    await queryRunner.query(`ALTER TABLE "recipe_items" DROP CONSTRAINT "FK_recipe_items_unit"`);
    await queryRunner.query(
      `ALTER TABLE "recipe_items" DROP CONSTRAINT "FK_recipe_items_material"`,
    );
    await queryRunner.query(`ALTER TABLE "recipe_items" DROP CONSTRAINT "FK_recipe_items_recipe"`);
    await queryRunner.query(`DROP TABLE "recipe_items"`);
  }
}
