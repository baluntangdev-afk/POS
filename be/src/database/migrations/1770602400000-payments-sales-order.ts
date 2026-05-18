import { MigrationInterface, QueryRunner } from 'typeorm';

export class PaymentsSalesOrder1770602400000 implements MigrationInterface {
  name = 'PaymentsSalesOrder1770602400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "payments" ADD "sales_order_id" integer`);
    await queryRunner.query(
      `ALTER TABLE "payments" ADD CONSTRAINT "FK_payments_sales_order" FOREIGN KEY ("sales_order_id") REFERENCES "sales_orders"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "payments" DROP CONSTRAINT "FK_payments_sales_order"`);
    await queryRunner.query(`ALTER TABLE "payments" DROP COLUMN "sales_order_id"`);
  }
}
