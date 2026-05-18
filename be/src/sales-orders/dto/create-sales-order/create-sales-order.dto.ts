import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsEnum, IsNotEmpty, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { SalesOrderType, SalesOrderStatus } from '../../sales-orders.enum';
import { CreateSalesOrderItemDto } from './sales-order-item.dto';
import { User } from '../../../users/entities/user.entity';

/**
 * DTO for creating a new sales order.
 */
export class CreateSalesOrderDto {
  @ApiProperty({ description: 'Sales order type', enum: SalesOrderType })
  @IsNotEmpty()
  @IsEnum(SalesOrderType)
  soType: SalesOrderType;

  @ApiProperty({
    type: () => [CreateSalesOrderItemDto],
    description: 'Line items: one product variant per line (id, quantity, price, modifierGroups)',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSalesOrderItemDto)
  products: CreateSalesOrderItemDto[];

  // Hidden from dto
  id?: string;
  soNumber: string;
  soDate: Date;
  vatExclusiveAmount: number;
  discountRate: number;
  discountAmount: number;
  taxRate: number;
  taxAmount: number;
  totalAmount: number;
  finalTotalAmount: number;
  status: SalesOrderStatus;
  createdBy: User;
  updatedBy: User;
}
