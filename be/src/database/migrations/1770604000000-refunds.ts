import { MigrationInterface, QueryRunner } from 'typeorm';

export class Refunds1770604000000 implements MigrationInterface {
  name = 'Refunds1770604000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."refunds_payment_method_enum" AS ENUM('Cash', 'Credit Card', 'GCash', 'Other')`,
    );
    await queryRunner.query(
      `CREATE TABLE "refunds" (
        "id" SERIAL NOT NULL,
        "refund_number" character varying(20) NOT NULL,
        "original_sales_order_id" integer NOT NULL,
        "reason" text NOT NULL,
        "total_refund_amount" numeric(12,2) NOT NULL,
        "payment_method" "public"."refunds_payment_method_enum" NOT NULL,
        "transaction_reference" character varying(100),
        "refund_date" TIMESTAMP NOT NULL DEFAULT now(),
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "UQ_refunds_refund_number" UNIQUE ("refund_number"),
        CONSTRAINT "PK_refunds" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_original_sales_order" FOREIGN KEY ("original_sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_updated_by"`);
    await queryRunner.query(`ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_created_by"`);
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_original_sales_order"`,
    );
    await queryRunner.query(`DROP TABLE "refunds"`);
    await queryRunner.query(`DROP TYPE "public"."refunds_payment_method_enum"`);
  }
}
