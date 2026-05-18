import { MigrationInterface, QueryRunner } from 'typeorm';

export class MaterialsTaxCategory1770367700000 implements MigrationInterface {
  name = 'MaterialsTaxCategory1770367700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "materials" ADD "tax_category_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "materials" ADD CONSTRAINT "FK_materials_tax_category" FOREIGN KEY ("tax_category_id") REFERENCES "tax_categories"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "materials" DROP CONSTRAINT "FK_materials_tax_category"`);
    await queryRunner.query(`ALTER TABLE "materials" DROP COLUMN "tax_category_id"`);
  }
}
