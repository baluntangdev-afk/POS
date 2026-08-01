import { ApiProperty } from '@nestjs/swagger';
import { SalesResponseDto } from './sales-response.dto';
import { HourlySalesDataItemDto } from './hourly-sales-response.dto';
import { ProductSalesDataItemDto } from './product-sales-response.dto';
import { ProductGroupSalesDataItemDto } from './product-group-sales-response.dto';
import { PaymentMethodSalesDataItemDto } from './payment-sales-response.dto';
import { UserSalesDataItemDto } from './user-sales-response.dto';

export class ExportableReportResponseDto {
  @ApiProperty({ example: '2026-06-02' })
  date: string;

  @ApiProperty({ example: 45 })
  count: number;

  @ApiProperty({ type: SalesResponseDto })
  summary: SalesResponseDto;

  @ApiProperty({ type: HourlySalesDataItemDto, isArray: true })
  hourlyBreakdown: HourlySalesDataItemDto[];

  @ApiProperty({ type: ProductSalesDataItemDto, isArray: true })
  byProduct: ProductSalesDataItemDto[];

  @ApiProperty({ type: ProductGroupSalesDataItemDto, isArray: true })
  byProductGroup: ProductGroupSalesDataItemDto[];

  @ApiProperty({ type: PaymentMethodSalesDataItemDto, isArray: true })
  byPayment: PaymentMethodSalesDataItemDto[];

  @ApiProperty({ type: UserSalesDataItemDto, isArray: true })
  byCashier: UserSalesDataItemDto[];
}
