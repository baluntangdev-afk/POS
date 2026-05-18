import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserIsPinChanged1770605600000 implements MigrationInterface {
  name = 'UserIsPinChanged1770605600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD "is_pin_changed" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "is_pin_changed"`);
  }
}
