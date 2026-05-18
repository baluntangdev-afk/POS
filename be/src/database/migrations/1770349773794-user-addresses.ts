import { MigrationInterface, QueryRunner } from 'typeorm';

export class UserAddresses1770349773794 implements MigrationInterface {
  name = 'UserAddresses1770349773794';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "user_addresses" ("id" SERIAL NOT NULL, "label" character varying(50) NOT NULL DEFAULT 'Shipping', "recipient_name" character varying(255) NOT NULL, "phone" character varying(20), "address_line1" character varying(255) NOT NULL, "address_line2" character varying(255), "city" character varying(100) NOT NULL, "state_province" character varying(100) NOT NULL, "postal_code" character varying(20) NOT NULL, "country" character varying(100) NOT NULL DEFAULT 'Philippines', "is_default" boolean NOT NULL DEFAULT false, "latitude" numeric(10,8), "longitude" numeric(11,8), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "user_id" integer NOT NULL, "created_by" integer, "updated_by" integer, "deleted_by" integer, CONSTRAINT "PK_8abbeb5e3239ff7877088ffc25b" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" ADD CONSTRAINT "FK_7a5100ce0548ef27a6f1533a5ce" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" ADD CONSTRAINT "FK_6d3d3b868cb01c5f04c82b33c2b" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" ADD CONSTRAINT "FK_b19d3d9050175c4967368e733bd" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" ADD CONSTRAINT "FK_9ee322ec8a10be5f356a0e5a49b" FOREIGN KEY ("deleted_by") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_addresses" DROP CONSTRAINT "FK_9ee322ec8a10be5f356a0e5a49b"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" DROP CONSTRAINT "FK_b19d3d9050175c4967368e733bd"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" DROP CONSTRAINT "FK_6d3d3b868cb01c5f04c82b33c2b"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_addresses" DROP CONSTRAINT "FK_7a5100ce0548ef27a6f1533a5ce"`,
    );
    await queryRunner.query(`DROP TABLE "user_addresses"`);
  }
}
