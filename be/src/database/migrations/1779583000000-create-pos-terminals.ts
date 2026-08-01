import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePosTerminals1779583000000 implements MigrationInterface {
  name = 'CreatePosTerminals1779583000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "pos_terminals" (
        "id" SERIAL NOT NULL,
        "kiosk_id" character varying(100) NOT NULL,
        "address" character varying(255) NOT NULL,
        "tin_number" character varying(50) NOT NULL,
        "payment_method" "payments_payment_method_enum" NOT NULL,
        "assigned_user_id" integer,
        "created_by" integer,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_by" integer,
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "deleted_by" integer,
        "deleted_at" TIMESTAMPTZ,
        CONSTRAINT "UQ_pos_terminals_kiosk_id" UNIQUE ("kiosk_id"),
        CONSTRAINT "PK_pos_terminals" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      ALTER TABLE "pos_terminals"
        ADD CONSTRAINT "FK_pos_terminals_assigned_user"
        FOREIGN KEY ("assigned_user_id") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);

    await queryRunner.query(`
      ALTER TABLE "pos_terminals"
        ADD CONSTRAINT "FK_pos_terminals_created_by"
        FOREIGN KEY ("created_by") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);

    await queryRunner.query(`
      ALTER TABLE "pos_terminals"
        ADD CONSTRAINT "FK_pos_terminals_updated_by"
        FOREIGN KEY ("updated_by") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);

    await queryRunner.query(`
      ALTER TABLE "pos_terminals"
        ADD CONSTRAINT "FK_pos_terminals_deleted_by"
        FOREIGN KEY ("deleted_by") REFERENCES "users"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "FK_pos_terminals_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "FK_pos_terminals_updated_by"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "FK_pos_terminals_created_by"`);
    await queryRunner.query(`ALTER TABLE "pos_terminals" DROP CONSTRAINT "FK_pos_terminals_assigned_user"`);
    await queryRunner.query(`DROP TABLE "pos_terminals"`);
  }
}
