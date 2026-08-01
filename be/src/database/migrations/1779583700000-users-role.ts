import { MigrationInterface, QueryRunner } from 'typeorm';

export class UsersRole1779583700000 implements MigrationInterface {
  name = 'UsersRole1779583700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "public"."users_role_enum" AS ENUM ('user', 'admin', 'supervisor')
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN "role" "public"."users_role_enum" NOT NULL DEFAULT 'user'
    `);
    await queryRunner.query(`
      UPDATE "users" SET "role" = 'admin' WHERE "system_admin" = true
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "role"`);
    await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
  }
}
