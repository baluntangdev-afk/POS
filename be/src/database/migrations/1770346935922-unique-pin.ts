import { MigrationInterface, QueryRunner } from 'typeorm';

export class UniquePin1770346935922 implements MigrationInterface {
  name = 'UniquePin1770346935922';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "device_pin" SET NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "users" ADD CONSTRAINT "UQ_5a64318715f54bddcfe985ca928" UNIQUE ("device_pin")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_5a64318715f54bddcfe985ca928"`);
    await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "device_pin" DROP NOT NULL`);
  }
}
