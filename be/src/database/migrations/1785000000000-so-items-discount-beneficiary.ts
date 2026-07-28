import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsDiscountBeneficiary1785000000000 implements MigrationInterface {
  name = 'SoItemsDiscountBeneficiary1785000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "so_items"
        ADD COLUMN "discount_beneficiary_id_number" varchar(100),
        ADD COLUMN "discount_beneficiary_name" varchar(255)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "so_items"
        DROP COLUMN "discount_beneficiary_name",
        DROP COLUMN "discount_beneficiary_id_number"
    `);
  }
}
