import type { MigrationInterface, QueryRunner } from 'typeorm';

export class PosTerminalPaymentMethodName1779583500000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE pos_terminal_payment_methods
      ADD COLUMN payment_method_name VARCHAR(100) NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE pos_terminal_payment_methods
      DROP COLUMN payment_method_name
    `);
  }
}
