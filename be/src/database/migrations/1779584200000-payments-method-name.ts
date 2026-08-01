import type { MigrationInterface, QueryRunner } from 'typeorm';

export class PaymentsMethodName1779584200000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE payments
      ADD COLUMN payment_method_name VARCHAR(100) NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE payments
      DROP COLUMN payment_method_name
    `);
  }
}
