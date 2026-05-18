import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserPermissionsMenuId1770605500000 implements MigrationInterface {
  name = 'UserPermissionsMenuId1770605500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "user_permissions" ADD "menu_id" integer`);
    await queryRunner.query(`ALTER TABLE "user_permissions" ALTER COLUMN "menu_id" SET NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "user_permissions" ADD CONSTRAINT "FK_user_permissions_menu" FOREIGN KEY ("menu_id") REFERENCES "menus"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_permissions" DROP CONSTRAINT "FK_user_permissions_menu"`,
    );
    await queryRunner.query(`ALTER TABLE "user_permissions" DROP COLUMN "menu_id"`);
  }
}
