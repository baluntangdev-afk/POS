import { MigrationInterface, QueryRunner } from 'typeorm';

export class FixAdminRole1779584300000 implements MigrationInterface {
  name = 'FixAdminRole1779584300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "users" SET "role" = 'admin' WHERE "system_admin" = true AND "role" = 'user'
    `);
  }

  public async down(_queryRunner: QueryRunner): Promise<void> {
    // No rollback — we cannot know which admins originally had role='user'
  }
}
