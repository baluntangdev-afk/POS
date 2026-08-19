import { MigrationInterface, QueryRunner } from 'typeorm';

export class PosTerminalsKioskIdVarchar1785100000000 implements MigrationInterface {
  name = 'PosTerminalsKioskIdVarchar1785100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "UQ_pos_terminals_kiosk_id"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" DROP DEFAULT`);
    await queryRunner.query(
      `ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" TYPE character varying(100) USING kiosk_id::text`,
    );
    await queryRunner.query(`ALTER TABLE "pos_terminals" ADD CONSTRAINT "UQ_pos_terminals_kiosk_id" UNIQUE ("kiosk_id")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "UQ_pos_terminals_kiosk_id"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" TYPE uuid USING kiosk_id::uuid`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ALTER COLUMN "kiosk_id" SET DEFAULT gen_random_uuid()`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" ADD CONSTRAINT "UQ_pos_terminals_kiosk_id" UNIQUE ("kiosk_id")`);
  }
}
