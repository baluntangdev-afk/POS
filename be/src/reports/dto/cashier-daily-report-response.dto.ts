import { ApiProperty } from '@nestjs/swagger';

export class ProductSalesLineDto {
  @ApiProperty({ description: 'Total quantity sold for this product', example: 4 })
  quantity: number;

  @ApiProperty({ description: 'Product line description', example: 'ICED COFFEE - Cafe Latte' })
  productName: string;

  @ApiProperty({ description: 'Total amount sold for this product', example: 460.0 })
  amount: number;
}

export class CashLedgerEntryDto {
  @ApiProperty({
    description: 'Payment timestamp (ISO 8601)',
    example: '2026-07-10T11:28:00.000Z',
  })
  time: string;

  @ApiProperty({
    description: 'Transaction reference number, if any',
    example: '278252216',
    nullable: true,
  })
  reference: string | null;

  @ApiProperty({ description: 'Cash amount paid for this transaction', example: 405.0 })
  amount: number;
}

export class CashierDailyReportResponseDto {
  @ApiProperty({ description: 'Cashier full name', example: 'Juan Dela Cruz' })
  cashierName: string;

  @ApiProperty({ description: 'Terminal/register name', example: 'POS-01' })
  terminalName: string;

  @ApiProperty({ description: 'Business date (today), formatted MM/DD/YYYY', example: '07/10/2026' })
  businessDate: string;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-10T14:32:10.000Z',
  })
  reportGeneratedAt: string;

  @ApiProperty({ description: 'Gross sales, net of refunds, excludes voided orders', example: 10839.0 })
  grossSales: number;

  @ApiProperty({ description: 'VAT-applicable sales (VAT-exclusive amount)', example: 9677.69 })
  vatableSales: number;

  @ApiProperty({ description: 'VAT amount collected', example: 1161.31 })
  vatAmount: number;

  @ApiProperty({ description: 'Sales from VAT-exempt orders (Senior/PWD)', example: 0 })
  vatExemptSales: number;

  @ApiProperty({ description: 'Zero-rated sales (not tracked; always 0)', example: 0 })
  zeroRatedSales: number;

  @ApiProperty({ description: 'Gross sales minus VAT amount', example: 9677.69 })
  netOfTax: number;

  @ApiProperty({ description: 'Completed transactions today', example: 73 })
  transactionCount: number;

  @ApiProperty({ description: 'Total quantity of items sold', example: 106 })
  totalQuantity: number;

  @ApiProperty({ description: 'Total amount collected in cash payments', example: 8158.0 })
  totalCashSales: number;

  @ApiProperty({ description: 'Number of cash payments', example: 56 })
  cashSalesCount: number;

  @ApiProperty({
    description: 'Itemized sales per product, sorted alphabetically by product name',
    type: ProductSalesLineDto,
    isArray: true,
  })
  salesByProduct: ProductSalesLineDto[];

  @ApiProperty({
    description: 'Itemized cash payments, oldest first',
    type: CashLedgerEntryDto,
    isArray: true,
  })
  cashLedger: CashLedgerEntryDto[];
}
