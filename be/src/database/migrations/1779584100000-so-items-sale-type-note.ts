import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsSaleTypeNote1779584100000 implements MigrationInterface {
  name = 'SoItemsSaleTypeNote1779584100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD COLUMN "sale_type" sales_orders_so_type_enum NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD COLUMN "note" varchar(500) NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN IF EXISTS "note"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN IF EXISTS "sale_type"`);
  }
}
