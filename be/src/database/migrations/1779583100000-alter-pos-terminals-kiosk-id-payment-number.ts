import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlterPosTerminalsKioskIdPaymentNumber1779583100000 implements MigrationInterface {
  name = 'AlterPosTerminalsKioskIdPaymentNumber1779583100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "UQ_pos_terminals_kiosk_id"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" TYPE uuid USING kiosk_id::uuid`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" SET DEFAULT gen_random_uuid()`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ADD CONSTRAINT "UQ_pos_terminals_kiosk_id" UNIQUE ("kiosk_id")`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ADD COLUMN "payment_number" character varying(50)`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP COLUMN "payment_number"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "UQ_pos_terminals_kiosk_id"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" TYPE character varying(100) USING kiosk_id::text`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" DROP DEFAULT`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ADD CONSTRAINT "UQ_pos_terminals_kiosk_id" UNIQUE ("kiosk_id")`);
  }
}
