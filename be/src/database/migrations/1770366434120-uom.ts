import { MigrationInterface, QueryRunner } from 'typeorm';

export class Uom1770366434120 implements MigrationInterface {
  name = 'Uom1770366434120';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "uoms" ("id" SERIAL NOT NULL, "name" character varying(50) NOT NULL, "code" character varying(10) NOT NULL, "whole_no" boolean, "status" character varying(20) NOT NULL DEFAULT 'Active', "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), "deleted_at" TIMESTAMP, "created_by" integer, "updated_by" integer, "deleted_by" integer, CONSTRAINT "PK_f207a792064e3032c8fe3922b22" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "uoms" ADD CONSTRAINT "FK_c373b979f2d99d9eb08e757f224" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "uoms" ADD CONSTRAINT "FK_e352d0caa8b860190a6812b5310" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "uoms" ADD CONSTRAINT "FK_2b9e0f014f247e551b21d95dea8" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "uoms" DROP CONSTRAINT "FK_2b9e0f014f247e551b21d95dea8"`);
    await queryRunner.query(`ALTER TABLE "uoms" DROP CONSTRAINT "FK_e352d0caa8b860190a6812b5310"`);
    await queryRunner.query(`ALTER TABLE "uoms" DROP CONSTRAINT "FK_c373b979f2d99d9eb08e757f224"`);
    await queryRunner.query(`DROP TABLE "uoms"`);
  }
}
