import { MigrationInterface, QueryRunner } from 'typeorm';

export class Discounts1770601823921 implements MigrationInterface {
  name = 'Discounts1770601823921';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."discounts_type_enum" AS ENUM('percentage', 'fixed_amount')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."discounts_status_enum" AS ENUM('Active', 'Inactive')`,
    );
    await queryRunner.query(
      `CREATE TABLE "discounts" (
        "id" SERIAL NOT NULL,
        "name" character varying(100) NOT NULL,
        "type" "public"."discounts_type_enum" NOT NULL,
        "value" numeric(12,2) NOT NULL,
        "status" "public"."discounts_status_enum" NOT NULL DEFAULT 'Active',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "UQ_discounts_name" UNIQUE ("name"),
        CONSTRAINT "PK_discounts" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "discounts" ADD CONSTRAINT "FK_discounts_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "discounts" ADD CONSTRAINT "FK_discounts_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "discounts" ADD CONSTRAINT "FK_discounts_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "discounts" DROP CONSTRAINT "FK_discounts_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "discounts" DROP CONSTRAINT "FK_discounts_updated_by"`);
    await queryRunner.query(`ALTER TABLE "discounts" DROP CONSTRAINT "FK_discounts_created_by"`);
    await queryRunner.query(`DROP TABLE "discounts"`);
    await queryRunner.query(`DROP TYPE "public"."discounts_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."discounts_type_enum"`);
  }
}
