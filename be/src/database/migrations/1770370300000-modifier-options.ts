import { MigrationInterface, QueryRunner } from 'typeorm';

export class ModifierOptions1770370300000 implements MigrationInterface {
  name = 'ModifierOptions1770370300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "modifier_options" (
        "id" SERIAL NOT NULL,
        "modifier_group_id" integer NOT NULL,
        "name" character varying(100) NOT NULL,
        "price_add_on" numeric(10,2) NOT NULL DEFAULT 0,
        "material_id" integer,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_modifier_options" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD CONSTRAINT "FK_modifier_options_modifier_group" FOREIGN KEY ("modifier_group_id") REFERENCES "modifier_groups"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD CONSTRAINT "FK_modifier_options_material" FOREIGN KEY ("material_id") REFERENCES "materials"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD CONSTRAINT "FK_modifier_options_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD CONSTRAINT "FK_modifier_options_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" ADD CONSTRAINT "FK_modifier_options_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "modifier_options" DROP CONSTRAINT "FK_modifier_options_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" DROP CONSTRAINT "FK_modifier_options_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" DROP CONSTRAINT "FK_modifier_options_created_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" DROP CONSTRAINT "FK_modifier_options_material"`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_options" DROP CONSTRAINT "FK_modifier_options_modifier_group"`,
    );
    await queryRunner.query(`DROP TABLE "modifier_options"`);
  }
}
