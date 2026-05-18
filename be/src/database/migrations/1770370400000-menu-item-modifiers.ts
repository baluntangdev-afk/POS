import { MigrationInterface, QueryRunner } from 'typeorm';

export class MenuItemModifiers1770370400000 implements MigrationInterface {
  name = 'MenuItemModifiers1770370400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "menu_item_modifiers" (
        "id" SERIAL NOT NULL,
        "menu_item_id" integer NOT NULL,
        "modifier_group_id" integer NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_menu_item_modifiers" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "FK_menu_item_modifiers_menu_item" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "FK_menu_item_modifiers_modifier_group" FOREIGN KEY ("modifier_group_id") REFERENCES "modifier_groups"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "FK_menu_item_modifiers_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "FK_menu_item_modifiers_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "FK_menu_item_modifiers_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" DROP CONSTRAINT "FK_menu_item_modifiers_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" DROP CONSTRAINT "FK_menu_item_modifiers_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" DROP CONSTRAINT "FK_menu_item_modifiers_created_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" DROP CONSTRAINT "FK_menu_item_modifiers_modifier_group"`,
    );
    await queryRunner.query(
      `ALTER TABLE "menu_item_modifiers" DROP CONSTRAINT "FK_menu_item_modifiers_menu_item"`,
    );
    await queryRunner.query(`DROP TABLE "menu_item_modifiers"`);
  }
}
