import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { SalesOrderType } from '../../sales-orders.enum';
import { PaymentDetailsDto } from './payment-details.dto';

/**
 * DTO for confirming a sales order (payment and status).
 */
export class ConfirmSalesOrderDto {
  @ApiProperty({
    type: () => PaymentDetailsDto,
    description: 'Payment details (payee, method, amounts, change)',
  })
  @ValidateNested()
  @Type(() => PaymentDetailsDto)
  payment_details: PaymentDetailsDto;

  @ApiProperty({
    description: 'Sales order type',
    enum: SalesOrderType,
    example: 'Dine-In',
  })
  @IsEnum(SalesOrderType)
  soType: SalesOrderType;
}
