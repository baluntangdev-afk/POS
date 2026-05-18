import { CreateSalesOrderDto } from './create-sales-order/create-sales-order.dto';

/**
 * DTO for updating a sales order (all fields optional).
 */
export class UpdateSalesOrderDto extends CreateSalesOrderDto {
  soItemId: string;
}
