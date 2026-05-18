import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrders1770602300000 implements MigrationInterface {
  name = 'SalesOrders1770602300000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."sales_orders_so_type_enum" AS ENUM('Dine-In', 'Take-Out', 'Delivery')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."sales_orders_status_enum" AS ENUM('Pending', 'Confirmed', 'Preparing', 'Ready', 'Completed', 'Cancelled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "sales_orders" (
        "id" SERIAL NOT NULL,
        "so_number" character varying(12) NOT NULL,
        "so_date" TIMESTAMP NOT NULL DEFAULT now(),
        "so_type" "public"."sales_orders_so_type_enum" NOT NULL DEFAULT 'Dine-In',
        "payee_name" character varying(100),
        "shipping_address" character varying(255),
        "location" character varying(255),
        "remarks" character varying(255),
        "status" "public"."sales_orders_status_enum" NOT NULL DEFAULT 'Pending',
        "discount_rate" numeric(5,2) DEFAULT 0,
        "discount_amount" numeric(12,2) NOT NULL DEFAULT 0,
        "tax_amount" numeric(12,2) NOT NULL DEFAULT 0,
        "final_total_amount" numeric(12,2) NOT NULL DEFAULT 0,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "approved_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        "approved_by" integer,
        CONSTRAINT "UQ_sales_orders_so_number" UNIQUE ("so_number"),
        CONSTRAINT "PK_sales_orders" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD CONSTRAINT "FK_sales_orders_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD CONSTRAINT "FK_sales_orders_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD CONSTRAINT "FK_sales_orders_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" ADD CONSTRAINT "FK_sales_orders_approved_by" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_approved_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "sales_orders" DROP CONSTRAINT "FK_sales_orders_created_by"`,
    );
    await queryRunner.query(`DROP TABLE "sales_orders"`);
    await queryRunner.query(`DROP TYPE "public"."sales_orders_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."sales_orders_so_type_enum"`);
  }
}
