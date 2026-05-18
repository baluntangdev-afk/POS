import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserEntity1770262063243 implements MigrationInterface {
  name = 'UserEntity1770262063243';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."users_suffix_enum" AS ENUM('None', 'Jr.', 'Sr.', 'I', 'II', 'III', 'IV', 'V')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_status_enum" AS ENUM('Active', 'Cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "users" ("id" SERIAL NOT NULL, "user_id" character varying(50) NOT NULL, "email" character varying(100) NOT NULL, "password" character varying(255) NOT NULL, "first_name" character varying(100) NOT NULL, "middle_name" character varying(100), "last_name" character varying(100) NOT NULL, "suffix" "public"."users_suffix_enum" DEFAULT 'None', "system_admin" boolean NOT NULL DEFAULT false, "image" character varying(255), "locked" boolean NOT NULL DEFAULT false, "last_login" TIMESTAMP WITH TIME ZONE, "status" "public"."users_status_enum" NOT NULL DEFAULT 'Active', "created_by" integer, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_by" integer, "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "deleted_by" integer, "deleted_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "UQ_96aac72f1574b88752e9fb00089" UNIQUE ("user_id"), CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "users"`);
    await queryRunner.query(`DROP TYPE "public"."users_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."users_suffix_enum"`);
  }
}
