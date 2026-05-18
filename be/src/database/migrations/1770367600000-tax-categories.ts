import { MigrationInterface, QueryRunner } from 'typeorm';

export class TaxCategories1770367600000 implements MigrationInterface {
  name = 'TaxCategories1770367600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "tax_categories" (
        "id" SERIAL NOT NULL,
        "name" character varying(50) NOT NULL,
        CONSTRAINT "PK_tax_categories" PRIMARY KEY ("id")
      )`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "tax_categories"`);
  }
}
