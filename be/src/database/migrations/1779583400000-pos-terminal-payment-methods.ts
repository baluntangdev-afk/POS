import type { MigrationInterface, QueryRunner } from 'typeorm';

export class PosTerminalPaymentMethods1779583400000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE pos_terminal_payment_methods (
        id SERIAL PRIMARY KEY,
        pos_terminal_id INT NOT NULL,
        payment_method payments_payment_method_enum NOT NULL,
        payment_number VARCHAR(50),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT fk_ptpm_terminal
          FOREIGN KEY (pos_terminal_id)
          REFERENCES pos_terminals(id)
          ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`ALTER TABLE pos_terminals DROP COLUMN payment_method`);
    await queryRunner.query(`ALTER TABLE pos_terminals DROP COLUMN payment_number`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE pos_terminal_payment_methods`);

    await queryRunner.query(`
      ALTER TABLE pos_terminals
        ADD COLUMN payment_method payments_payment_method_enum NOT NULL DEFAULT 'Cash',
        ADD COLUMN payment_number VARCHAR(50)
    `);
  }
}
