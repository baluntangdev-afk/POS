import { MigrationInterface, QueryRunner } from 'typeorm';

export class Recipes1770371000000 implements MigrationInterface {
  name = 'Recipes1770371000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."recipes_status_enum" AS ENUM('Active', 'Archived', 'Draft')`,
    );
    await queryRunner.query(
      `CREATE TABLE "recipes" (
        "id" SERIAL NOT NULL,
        "product_variant_id" integer NOT NULL,
        "name" character varying(150) NOT NULL,
        "prep_time_minutes" integer,
        "yield_qty" numeric(12,3) NOT NULL DEFAULT 1,
        "yield_unit_id" integer NOT NULL,
        "status" "public"."recipes_status_enum" NOT NULL DEFAULT 'Draft',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "UQ_recipes_product_variant_id" UNIQUE ("product_variant_id"),
        CONSTRAINT "PK_recipes" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD CONSTRAINT "FK_recipes_product_variant" FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD CONSTRAINT "FK_recipes_yield_unit" FOREIGN KEY ("yield_unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD CONSTRAINT "FK_recipes_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD CONSTRAINT "FK_recipes_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD CONSTRAINT "FK_recipes_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "recipes" DROP CONSTRAINT "FK_recipes_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "recipes" DROP CONSTRAINT "FK_recipes_updated_by"`);
    await queryRunner.query(`ALTER TABLE "recipes" DROP CONSTRAINT "FK_recipes_created_by"`);
    await queryRunner.query(`ALTER TABLE "recipes" DROP CONSTRAINT "FK_recipes_yield_unit"`);
    await queryRunner.query(`ALTER TABLE "recipes" DROP CONSTRAINT "FK_recipes_product_variant"`);
    await queryRunner.query(`DROP TABLE "recipes"`);
    await queryRunner.query(`DROP TYPE "public"."recipes_status_enum"`);
  }
}
