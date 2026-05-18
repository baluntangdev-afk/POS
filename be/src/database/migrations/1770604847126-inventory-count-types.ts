import { MigrationInterface, QueryRunner } from 'typeorm';

export class InventoryCountTypes1770604847126 implements MigrationInterface {
  name = 'InventoryCountTypes1770604847126';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "inventory_count_types" (
        "id" SERIAL NOT NULL,
        "name" character varying(20) NOT NULL,
        CONSTRAINT "PK_inventory_count_types" PRIMARY KEY ("id")
      )`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "inventory_count_types"`);
  }
}
