import { ApiProperty } from '@nestjs/swagger';

/**
 * One payment method row in the payment sales report.
 */
export class PaymentMethodSalesDataItemDto {
  @ApiProperty({ description: 'Payment method id', example: 1 })
  id: number;

  @ApiProperty({ description: 'Payment method name', example: 'Cash' })
  name: string;

  @ApiProperty({
    description: 'Total sales (SO.final_total_amount) for this payment method',
    example: 700,
  })
  totalSales: number;
}
