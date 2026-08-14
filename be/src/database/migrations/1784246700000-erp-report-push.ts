import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * ERP back-office: retry queue for pushing closed X / Daily / Z report snapshots.
 */
export class ErpReportPush1784246700000 implements MigrationInterface {
  name = 'ErpReportPush1784246700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "erp_report_push" (
        "id" SERIAL NOT NULL,
        "report_type" character varying(30) NOT NULL,
        "client_report_id" character varying(64) NOT NULL,
        "snapshot" jsonb NOT NULL,
        "status" character varying(20) NOT NULL DEFAULT 'Pending',
        "attempts" integer NOT NULL DEFAULT 0,
        "last_error" text,
        "last_attempt_at" TIMESTAMP,
        "sent_at" TIMESTAMP,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_erp_report_push" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(
      `CREATE UNIQUE INDEX "UQ_erp_report_push_type_client" ON "erp_report_push" ("report_type", "client_report_id")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "erp_report_push"`);
  }
}
