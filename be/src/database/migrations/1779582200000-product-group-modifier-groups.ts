import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProductGroupModifierGroups1779582200000 implements MigrationInterface {
  name = 'ProductGroupModifierGroups1779582200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "product_group_modifier_groups" (
        "product_group_id"  INTEGER NOT NULL,
        "modifier_group_id" INTEGER NOT NULL,
        "sort_order"        INT     NOT NULL DEFAULT 0,
        CONSTRAINT "PK_product_group_modifier_groups"
          PRIMARY KEY ("product_group_id", "modifier_group_id"),
        CONSTRAINT "FK_pgmg_product_group"
          FOREIGN KEY ("product_group_id")
            REFERENCES "product_groups"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_pgmg_modifier_group"
          FOREIGN KEY ("modifier_group_id")
            REFERENCES "modifier_groups"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_pgmg_product_group_id" ON "product_group_modifier_groups"("product_group_id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_pgmg_product_group_id"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "product_group_modifier_groups"`);
  }
}
