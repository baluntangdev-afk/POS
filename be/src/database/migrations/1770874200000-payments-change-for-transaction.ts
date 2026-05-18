import { MigrationInterface, QueryRunner } from 'typeorm';

export class PaymentsChangeForTransaction1770874200000 implements MigrationInterface {
  name = 'PaymentsChangeForTransaction1770874200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "payments" ADD "change" numeric(12,2) NOT NULL DEFAULT 0`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "payments" DROP COLUMN "change"`);
  }
}
