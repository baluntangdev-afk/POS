import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsSoDiscountId1770873862938 implements MigrationInterface {
  name = 'SoItemsSoDiscountId1770873862938';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" ADD "so_discount_id" uuid`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_so_discount" FOREIGN KEY ("so_discount_id") REFERENCES "so_discounts"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_so_discount"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "so_discount_id"`);
  }
}
