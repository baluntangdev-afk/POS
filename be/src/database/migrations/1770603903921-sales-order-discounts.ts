import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrderDiscounts1770603903921 implements MigrationInterface {
  name = 'SalesOrderDiscounts1770603903921';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "so_discounts" (
        "id" SERIAL NOT NULL,
        "sales_order_id" integer NOT NULL,
        "discount_id" integer NOT NULL,
        "applied_amount" numeric(12,2) NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_so_discounts" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "FK_so_discounts_sales_order_id" FOREIGN KEY ("sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "FK_so_discounts_discount_id" FOREIGN KEY ("discount_id") REFERENCES "discounts"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "FK_so_discounts_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "FK_so_discounts_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" ADD CONSTRAINT "FK_so_discounts_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "so_discounts" DROP CONSTRAINT "FK_so_discounts_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" DROP CONSTRAINT "FK_so_discounts_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" DROP CONSTRAINT "FK_so_discounts_created_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" DROP CONSTRAINT "FK_so_discounts_discount_id"`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_discounts" DROP CONSTRAINT "FK_so_discounts_sales_order_id"`,
    );
    await queryRunner.query(`DROP TABLE "so_discounts"`);
  }
}
