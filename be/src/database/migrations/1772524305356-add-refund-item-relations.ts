import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddRefundItemRelations1772524305356 implements MigrationInterface {
  name = 'AddRefundItemRelations1772524305356';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_created_by"`);
    await queryRunner.query(`ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_updated_by"`);
    await queryRunner.query(`ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_deleted_by"`);
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_refunds_original_sales_order"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_refund_items_refund_id"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_refund_items_sales_order_item_id"`,
    );
    await queryRunner.query(
      `ALTER TYPE "public"."refunds_payment_method_enum" RENAME TO "refunds_payment_method_enum_old"`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."refunds_payment_method_enum" AS ENUM('Cash', 'Credit Card', 'GCash', 'Other')`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ALTER COLUMN "payment_method" TYPE "public"."refunds_payment_method_enum" USING "payment_method"::"text"::"public"."refunds_payment_method_enum"`,
    );
    await queryRunner.query(`DROP TYPE "public"."refunds_payment_method_enum_old"`);
    await queryRunner.query(`ALTER TABLE "refunds" ALTER COLUMN "created_by" DROP NOT NULL`);
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_389c53cd8634c17a948ae3b2d50" FOREIGN KEY ("original_sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_dcf8f786aaeb2746c93a332b635" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_b1862e904d65e13aa2625841f2a" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_42f0392b1917b5307432ee6113e" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_79cde544708be9a0407c4b20bef" FOREIGN KEY ("refund_id") REFERENCES "refunds"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_4d7b847439e336b05a90c3c141d" FOREIGN KEY ("sales_order_item_id") REFERENCES "so_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_4d7b847439e336b05a90c3c141d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" DROP CONSTRAINT "FK_79cde544708be9a0407c4b20bef"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_42f0392b1917b5307432ee6113e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_b1862e904d65e13aa2625841f2a"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_dcf8f786aaeb2746c93a332b635"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" DROP CONSTRAINT "FK_389c53cd8634c17a948ae3b2d50"`,
    );
    await queryRunner.query(`ALTER TABLE "refunds" ALTER COLUMN "created_by" SET NOT NULL`);
    await queryRunner.query(
      `CREATE TYPE "public"."refunds_payment_method_enum_old" AS ENUM('Cash', 'Credit Card', 'GCash', 'Other')`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ALTER COLUMN "payment_method" TYPE "public"."refunds_payment_method_enum_old" USING "payment_method"::"text"::"public"."refunds_payment_method_enum_old"`,
    );
    await queryRunner.query(`DROP TYPE "public"."refunds_payment_method_enum"`);
    await queryRunner.query(
      `ALTER TYPE "public"."refunds_payment_method_enum_old" RENAME TO "refunds_payment_method_enum"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_refund_items_sales_order_item_id" FOREIGN KEY ("sales_order_item_id") REFERENCES "so_items"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refund_items" ADD CONSTRAINT "FK_refund_items_refund_id" FOREIGN KEY ("refund_id") REFERENCES "refunds"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_original_sales_order" FOREIGN KEY ("original_sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refunds" ADD CONSTRAINT "FK_refunds_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }
}
