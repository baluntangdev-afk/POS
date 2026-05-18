import { MigrationInterface, QueryRunner } from 'typeorm';

export class TaxCategoriesValue1770606400000 implements MigrationInterface {
  name = 'TaxCategoriesValue1770606400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tax_categories" ADD "value" numeric(12,2) NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "tax_categories" DROP COLUMN "value"`);
  }
}
