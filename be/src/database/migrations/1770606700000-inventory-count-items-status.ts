import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountItemsStatus1770606700000 implements MigrationInterface {
  name = 'InventoryCountItemsStatus1770606700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "inventory_count_items_status_enum" AS ENUM('Pending', 'Synced')`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_count_items" ADD "status" "inventory_count_items_status_enum" NOT NULL DEFAULT 'Pending'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "inventory_count_items" DROP COLUMN "status"`);
    await queryRunner.query(`DROP TYPE "inventory_count_items_status_enum"`);
  }
}
