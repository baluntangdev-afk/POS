import { MigrationInterface, QueryRunner } from 'typeorm';

export class UsersPosTerminalId1779583300000 implements MigrationInterface {
  name = 'UsersPosTerminalId1779583300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN "pos_terminal_id" integer,
        ADD CONSTRAINT "fk_users_pos_terminal_id"
          FOREIGN KEY ("pos_terminal_id")
          REFERENCES "pos_terminals" ("id")
          ON DELETE SET NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP CONSTRAINT "fk_users_pos_terminal_id",
        DROP COLUMN "pos_terminal_id"
    `);
  }
}
