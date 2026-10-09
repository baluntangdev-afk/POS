import { MigrationInterface, QueryRunner, TableColumn, TableIndex } from 'typeorm';

export class AddClientRequestIdToSalesOrders1779582200000 implements MigrationInterface {
  name = 'AddClientRequestIdToSalesOrders1779582200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'sales_orders',
      new TableColumn({
        name: 'client_request_id',
        type: 'varchar',
        length: '100',
        isNullable: true,
      }),
    );

    await queryRunner.createIndex(
      'sales_orders',
      new TableIndex({
        name: 'IDX_sales_orders_client_request_id',
        columnNames: ['client_request_id'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('sales_orders', 'IDX_sales_orders_client_request_id');
    await queryRunner.dropColumn('sales_orders', 'client_request_id');
  }
}
