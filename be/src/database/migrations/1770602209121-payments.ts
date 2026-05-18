import { MigrationInterface, QueryRunner } from 'typeorm';

export class Payments1770602209121 implements MigrationInterface {
  name = 'Payments1770602209121';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."payments_payment_method_enum" AS ENUM('Cash', 'Credit Card', 'GCash', 'Other')`,
    );
    await queryRunner.query(
      `CREATE TABLE "payments" (
        "id" SERIAL NOT NULL,
        "amount_paid" numeric(12,2) NOT NULL,
        "payment_method" "public"."payments_payment_method_enum" NOT NULL,
        "payment_date" TIMESTAMP NOT NULL DEFAULT now(),
        "transaction_reference" character varying(100),
        CONSTRAINT "PK_payments" PRIMARY KEY ("id")
      )`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "payments"`);
    await queryRunner.query(`DROP TYPE "public"."payments_payment_method_enum"`);
  }
}
