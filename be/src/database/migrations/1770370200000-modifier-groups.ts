import { MigrationInterface, QueryRunner } from 'typeorm';

export class ModifierGroups1770370200000 implements MigrationInterface {
  name = 'ModifierGroups1770370200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "modifier_groups" (
        "id" SERIAL NOT NULL,
        "name" character varying(100) NOT NULL,
        "min_selection" integer NOT NULL DEFAULT 0,
        "max_selection" integer NOT NULL DEFAULT 1,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_modifier_groups" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" ADD CONSTRAINT "FK_modifier_groups_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" ADD CONSTRAINT "FK_modifier_groups_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" ADD CONSTRAINT "FK_modifier_groups_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" DROP CONSTRAINT "FK_modifier_groups_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" DROP CONSTRAINT "FK_modifier_groups_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "modifier_groups" DROP CONSTRAINT "FK_modifier_groups_created_by"`,
    );
    await queryRunner.query(`DROP TABLE "modifier_groups"`);
  }
}
