import { MigrationInterface, QueryRunner } from 'typeorm';

export class Materials1770367283716 implements MigrationInterface {
  name = 'Materials1770367283716';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."materials_dispense_type_enum" AS ENUM('FEFO', 'FIFO', 'LIFO')`,
    );
    await queryRunner.query(
      `CREATE TABLE "materials" (
        "id" SERIAL NOT NULL,
        "material_code" character varying(15) NOT NULL,
        "material_name" character varying(100) NOT NULL,
        "material_specification" text,
        "status" character varying(20) NOT NULL DEFAULT 'Active',
        "material_type_id" integer NOT NULL,
        "standard_packing_unit_id" integer,
        "standard_packing_qty" numeric(18,4),
        "standard_issuance_unit_id" integer,
        "standard_issuance_qty" numeric(18,4),
        "standard_base_unit_id" integer NOT NULL,
        "standard_base_qty" numeric(18,4) NOT NULL DEFAULT 1,
        "material_lead_time" numeric(18,4),
        "minimum_stock_level_qty" numeric(18,4),
        "maximum_stock_level_qty" numeric(18,4),
        "dispense_type" "public"."materials_dispense_type_enum" NOT NULL DEFAULT 'FEFO',
        "shelf_life_days" numeric(18,4),
        "weight" numeric(18,4),
        "image" character varying(255),
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        "deleted_at" TIMESTAMP,
        "created_by" integer NOT NULL,
        "updated_by" integer,
        "deleted_by" integer,
        CONSTRAINT "UQ_materials_material_code" UNIQUE ("material_code"),
        CONSTRAINT "PK_materials" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_material_type" FOREIGN KEY ("material_type_id") REFERENCES "material_types"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_standard_packing_unit" FOREIGN KEY ("standard_packing_unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_standard_issuance_unit" FOREIGN KEY ("standard_issuance_unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_standard_base_unit" FOREIGN KEY ("standard_base_unit_id") REFERENCES "uoms"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_created_by" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_updated_by" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_deleted_by" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_deleted_by"`);
    await queryRunner.query(`ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_updated_by"`);
    await queryRunner.query(`ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_created_by"`);
    await queryRunner.query(
      `ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_standard_base_unit"`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_standard_issuance_unit"`,
    );
    await queryRunner.query(
      `ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_standard_packing_unit"`,
    );
    await queryRunner.query(`ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_material_type"`);
    await queryRunner.query(`DROP TABLE "materials"`);
    await queryRunner.query(`DROP TYPE "public"."materials_dispense_type_enum"`);
  }
}
