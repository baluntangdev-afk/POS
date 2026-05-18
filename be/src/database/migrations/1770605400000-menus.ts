import { MigrationInterface, QueryRunner } from 'typeorm';

export class Menus1770605400000 implements MigrationInterface {
  name = 'Menus1770605400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."menus_status_enum" AS ENUM('Active', 'Cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "menus" (
        "id" SERIAL NOT NULL,
        "menu_code" character varying(4) NOT NULL,
        "menu_name" character varying(50) NOT NULL,
        "permissions" text[] NOT NULL DEFAULT '{}',
        "status" "public"."menus_status_enum" NOT NULL DEFAULT 'Active',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_menus" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "menus" ADD CONSTRAINT "FK_menus_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "menus" ADD CONSTRAINT "FK_menus_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "menus" ADD CONSTRAINT "FK_menus_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "menus" DROP CONSTRAINT "FK_menus_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "menus" DROP CONSTRAINT "FK_menus_updated_by"`);
    await queryRunner.query(`ALTER TABLE "menus" DROP CONSTRAINT "FK_menus_created_by"`);
    await queryRunner.query(`DROP TABLE "menus"`);
    await queryRunner.query(`DROP TYPE "public"."menus_status_enum"`);
  }
}
