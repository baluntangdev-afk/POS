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
  @ApiProperty({
    description: 'Persisted report id; null for a live, not-yet-closed preview',
    nullable: true,
    example: '0198f2b1-7c3a-7c3a-8b1a-2f6e9c1d4a10',
  })
  id: string | null;

  @ApiProperty({ description: 'Cashier full name', example: 'Juan Dela Cruz' })
  cashierName: string;

  @ApiProperty({ description: 'Terminal/register name', example: 'POS-01' })
  terminalName: string;

  @ApiProperty({
    description: 'Earliest unreported transaction in this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-10T20:15:00.000Z',
  })
  periodStart: string | null;

  @ApiProperty({
    description: 'Latest unreported transaction in this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-11T03:02:00.000Z',
  })
  periodEnd: string | null;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-10T14:32:10.000Z',
  })
  reportGeneratedAt: string;

  @ApiProperty({
    description: 'Gross sales, net of refunds, excludes voided orders',
    example: 10839.0,
  })
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

export class CashierDailyReportHistoryItemDto {
  @ApiProperty({ description: 'Report id', example: '0198f2b1-7c3a-7c3a-8b1a-2f6e9c1d4a10' })
  id: string;

  @ApiProperty({
    description: 'Earliest transaction covered by this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-10T20:15:00.000Z',
  })
  periodStart: string | null;

  @ApiProperty({
    description: 'Latest transaction covered by this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-11T03:02:00.000Z',
  })
  periodEnd: string | null;

  @ApiProperty({ description: 'When this report was closed/generated (ISO 8601)' })
  generatedAt: string;

  @ApiProperty({ description: 'Gross sales for this report', example: 10839.0 })
  grossSales: number;

  @ApiProperty({ description: 'Completed transactions in this report', example: 73 })
  transactionCount: number;
}
