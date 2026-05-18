import { MigrationInterface, QueryRunner } from 'typeorm';

export class ProductGroups1770605100000 implements MigrationInterface {
  name = 'ProductGroups1770605100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "product_groups" (
        "id" SERIAL NOT NULL,
        "name" character varying(100) NOT NULL,
        "description" text,
        "image_url" character varying(255),
        "status" character varying(20) NOT NULL DEFAULT 'Active',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "UQ_product_groups_name" UNIQUE ("name"),
        CONSTRAINT "PK_product_groups" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "product_groups" ADD CONSTRAINT "FK_product_groups_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "product_groups" ADD CONSTRAINT "FK_product_groups_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "product_groups" ADD CONSTRAINT "FK_product_groups_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "product_groups" DROP CONSTRAINT "FK_product_groups_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "product_groups" DROP CONSTRAINT "FK_product_groups_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "product_groups" DROP CONSTRAINT "FK_product_groups_created_by"`,
    );
    await queryRunner.query(`DROP TABLE "product_groups"`);
  }
}
