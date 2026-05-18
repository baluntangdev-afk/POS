import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserDetails1770345160261 implements MigrationInterface {
  name = 'UserDetails1770345160261';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."user_details_gender_enum" AS ENUM('Male', 'Female', 'Other', 'PreferNotToSay')`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_details" ("id" SERIAL NOT NULL, "username" character varying(100), "gender" "public"."user_details_gender_enum", "date_of_birth" date, "bio" text, "profile_picture" character varying(500), "profile_picture_path" character varying(255), "phone" character varying(20), "phone_verified_at" TIMESTAMP, "email_verified_at" TIMESTAMP, "timezone" character varying(50) NOT NULL DEFAULT 'UTC', "locale" character varying(10) NOT NULL DEFAULT 'en_US', "notification_preferences" jsonb, "address" text, "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), "user_id" integer NOT NULL, "created_by" integer, "updated_by" integer, CONSTRAINT "PK_fb08394d3f499b9e441cab9ca51" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(`ALTER TABLE "users" ADD "salt" character varying(255) NOT NULL`);
    await queryRunner.query(`ALTER TABLE "users" ADD "device_pin" character varying(255)`);
    await queryRunner.query(`ALTER TABLE "users" ADD "phone" character varying(20)`);
    await queryRunner.query(
      `ALTER TABLE "users" ADD "email_verified" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "phone_verified" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_details" ADD CONSTRAINT "FK_ef1a1915f99bcf7a87049f74494" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_details" ADD CONSTRAINT "FK_11e99be7250e19fe0f57de148e7" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_details" ADD CONSTRAINT "FK_790c8a9b6ce5d5f7679188f8422" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_details" DROP CONSTRAINT "FK_790c8a9b6ce5d5f7679188f8422"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_details" DROP CONSTRAINT "FK_11e99be7250e19fe0f57de148e7"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_details" DROP CONSTRAINT "FK_ef1a1915f99bcf7a87049f74494"`,
    );
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "phone_verified"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "email_verified"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "phone"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "device_pin"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "salt"`);
    await queryRunner.query(`DROP TABLE "user_details"`);
    await queryRunner.query(`DROP TYPE "public"."user_details_gender_enum"`);
  }
}
