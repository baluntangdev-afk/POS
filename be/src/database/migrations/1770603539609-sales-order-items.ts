import { MigrationInterface, QueryRunner } from 'typeorm';

export class SalesOrderItems1770603539609 implements MigrationInterface {
  name = 'SalesOrderItems1770603539609';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "so_items" (
        "id" SERIAL NOT NULL,
        "so_id" integer NOT NULL,
        "item_sequence" integer,
        "product_variant_id" integer NOT NULL,
        "recipe_id" integer NOT NULL,
        "qty" numeric(12,3) NOT NULL,
        "uom" integer,
        "unit_price" numeric(12,2) NOT NULL,
        "item_discount_rate" numeric(5,2) DEFAULT 0,
        "item_discounted_price" numeric(12,2),
        "item_total_amount" numeric(12,2) NOT NULL,
        "item_paid_amount" numeric(12,2) DEFAULT 0,
        "currency" integer,
        "status" character varying(20) NOT NULL DEFAULT 'Pending',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_so_items" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_so_id" FOREIGN KEY ("so_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_product_variant_id" FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_recipe_id" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_uom" FOREIGN KEY ("uom") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_currency" FOREIGN KEY ("currency") REFERENCES "currencies"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "so_items" ADD CONSTRAINT "FK_so_items_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_updated_by"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_created_by"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_currency"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_uom"`);
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_recipe_id"`);
    await queryRunner.query(
      `ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_product_variant_id"`,
    );
    await queryRunner.query(`ALTER TABLE "so_items" DROP CONSTRAINT "FK_so_items_so_id"`);
    await queryRunner.query(`DROP TABLE "so_items"`);
  }
}
