import { MigrationInterface, QueryRunner } from 'typeorm';

export class StoreMenus1770368100000 implements MigrationInterface {
  name = 'StoreMenus1770368100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."store_menus_status_enum" AS ENUM('Active', 'Seasonal', 'Archived')`,
    );
    await queryRunner.query(
      `CREATE TABLE "store_menus" (
        "id" SERIAL NOT NULL,
        "name" character varying(100) NOT NULL,
        "description" text,
        "status" "public"."store_menus_status_enum" NOT NULL DEFAULT 'Active',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "UQ_store_menus_name" UNIQUE ("name"),
        CONSTRAINT "PK_store_menus" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "store_menus" ADD CONSTRAINT "FK_store_menus_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "store_menus" ADD CONSTRAINT "FK_store_menus_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "store_menus" ADD CONSTRAINT "FK_store_menus_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "store_menus" DROP CONSTRAINT "FK_store_menus_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "store_menus" DROP CONSTRAINT "FK_store_menus_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "store_menus" DROP CONSTRAINT "FK_store_menus_created_by"`,
    );
    await queryRunner.query(`DROP TABLE "store_menus"`);
    await queryRunner.query(`DROP TYPE "public"."store_menus_status_enum"`);
  }
}
