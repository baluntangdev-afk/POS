import { MigrationInterface, QueryRunner } from 'typeorm';

export class Currencies1770367500000 implements MigrationInterface {
  name = 'Currencies1770367500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "currencies" (
        "id" SERIAL NOT NULL,
        "code" character varying(3) NOT NULL,
        "name" character varying(50) NOT NULL,
        "sign" character varying(5),
        "is_default" boolean NOT NULL DEFAULT false,
        CONSTRAINT "UQ_currencies_code" UNIQUE ("code"),
        CONSTRAINT "PK_currencies" PRIMARY KEY ("id")
      )`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "currencies"`);
  }
}
