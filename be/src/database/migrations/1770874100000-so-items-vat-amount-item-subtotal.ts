import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsVatAmountItemSubtotal1770874100000 implements MigrationInterface {
  name = 'SoItemsVatAmountItemSubtotal1770874100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" ADD "vat_amount" numeric(12,2)`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD "item_subtotal" numeric(12,2) NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "item_subtotal"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "vat_amount"`);
  }
}
