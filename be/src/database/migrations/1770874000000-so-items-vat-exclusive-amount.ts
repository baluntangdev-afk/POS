import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsVatExclusiveAmount1770874000000 implements MigrationInterface {
  name = 'SoItemsVatExclusiveAmount1770874000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" ADD "vat_exclusive_amount" numeric(12,2)`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "vat_exclusive_amount"`);
  }
}
