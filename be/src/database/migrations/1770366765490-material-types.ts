import { MigrationInterface, QueryRunner } from 'typeorm';

export class MaterialTypes1770366765490 implements MigrationInterface {
  name = 'MaterialTypes1770366765490';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "material_types" (
        "id" SERIAL NOT NULL,
        "material_type_code" character varying(3) NOT NULL,
        "material_type_name" character varying(100) NOT NULL,
        "auto_material_code" boolean NOT NULL DEFAULT false,
        "status" character varying(20) NOT NULL DEFAULT 'Active',
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "PK_material_types" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "material_types" ADD CONSTRAINT "FK_material_types_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "material_types" ADD CONSTRAINT "FK_material_types_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "material_types" ADD CONSTRAINT "FK_material_types_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "material_types" DROP CONSTRAINT "FK_material_types_deleted_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "material_types" DROP CONSTRAINT "FK_material_types_updated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "material_types" DROP CONSTRAINT "FK_material_types_created_by"`,
    );
    await queryRunner.query(`DROP TABLE "material_types"`);
  }
}
