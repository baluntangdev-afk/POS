import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Local sellable count for ERP-synced menu items. Seeded from ERP
 * available_servings on menu sync; decremented on each confirmed sale so the
 * kiosk can stop selling before the next 5-minute ERP sync.
 */
export class ProductAvailableServings1784246600000 implements MigrationInterface {
  name = 'ProductAvailableServings1784246600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "available_servings" integer`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "products" DROP COLUMN IF EXISTS "available_servings"`);
  }
}
