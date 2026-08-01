import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlterPosTerminalsAddLegalName1779583200000 implements MigrationInterface {
  name = 'AlterPosTerminalsAddLegalName1779583200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" ADD COLUMN "legal_name" character varying(255)`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP COLUMN "legal_name"`);
  }
}
