import { MigrationInterface, QueryRunner } from 'typeorm';

export class SoItemsParentSoItemId1770873956257 implements MigrationInterface {
  name = 'SoItemsParentSoItemId1770873956257';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" ADD "parent_so_item_id" uuid`);
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_parent_so_item" FOREIGN KEY ("parent_so_item_id") REFERENCES "so_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_parent_so_item"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP COLUMN "parent_so_item_id"`);
  }
}
