import { ApiProperty } from '@nestjs/swagger';
import { NameAmountDto } from './cashier-x-reading-response.dto';

export class ZReadingCashierBreakdownDto {
  @ApiProperty({ description: 'Cashier user id', example: 7 })
  cashierId: number;

  @ApiProperty({ description: 'Cashier full name', example: 'Juan Dela Cruz' })
  cashierName: string;

  @ApiProperty({ description: 'Completed transactions rung up by this cashier', example: 18 })
  transactionCount: number;

  @ApiProperty({ description: 'Sales total rung up by this cashier', example: 8420.5 })
  salesTotal: number;
}

export class ZReadingResponseDto {
  @ApiProperty({
    description: 'Persisted report id; null for a live, not-yet-closed preview',
    nullable: true,
    example: '0198f2b1-7c3a-7c3a-8b1a-2f6e9c1d4a10',
  })
  id: string | null;

  @ApiProperty({
    description: 'Sequential Z-counter; null for a live, not-yet-closed preview',
    nullable: true,
    example: 14,
  })
  zCounter: number | null;

  @ApiProperty({ description: 'Terminal/register name', example: 'POS-01' })
  terminalName: string;

  @ApiProperty({
    description: 'Cashier who triggered the close; null for a live preview',
    nullable: true,
    example: 'Juan Dela Cruz',
  })
  closedByName: string | null;

  @ApiProperty({
    description: 'Supervisor/admin who authorized the close; null for a live preview',
    nullable: true,
    example: 'Maria Santos',
  })
  authorizedByName: string | null;

  @ApiProperty({
    description: 'Earliest unreported transaction store-wide, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-14T22:00:00.000Z',
  })
  periodStart: string | null;

  @ApiProperty({
    description: 'Latest unreported transaction store-wide, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-15T13:45:00.000Z',
  })
  periodEnd: string | null;

  @ApiProperty({
    description: 'Report generation timestamp (ISO 8601)',
    example: '2026-07-15T14:00:00.000Z',
  })
  reportGeneratedAt: string;

  @ApiProperty({
    description: 'Grand cumulative total as of the previous Z-Reading close (0 if first ever)',
    example: 152340.0,
  })
  beginningBalance: number;

  @ApiProperty({
    description: 'Grand cumulative total including this period (beginningBalance + totalSales)',
    example: 171390.0,
  })
  endingBalance: number;

  @ApiProperty({
    description: 'Sales grouped by payment method, store-wide',
    type: NameAmountDto,
    isArray: true,
  })
  salesByPaymentMethod: NameAmountDto[];

  @ApiProperty({
    description: 'Sales grouped by product category (product group), store-wide',
    type: NameAmountDto,
    isArray: true,
  })
  salesByCategory: NameAmountDto[];

  @ApiProperty({
    description: 'Total sales, net of refunds, excludes voided orders',
    example: 19050.0,
  })
  totalSales: number;

  @ApiProperty({ description: 'Total transactions (completed + voided)', example: 43 })
  totalTransactions: number;

  @ApiProperty({ description: 'Completed transactions', example: 42 })
  completedTransactions: number;

  @ApiProperty({ description: 'Voided (cancelled) transactions', example: 1 })
  voidedTransactions: number;

  @ApiProperty({ description: 'Transactions with at least one refund', example: 1 })
  refundedTransactions: number;

  @ApiProperty({
    description: 'Discounts grouped by discount name, store-wide',
    type: NameAmountDto,
    isArray: true,
  })
  discounts: NameAmountDto[];

  @ApiProperty({ description: 'Total discounts applied', example: 665.0 })
  totalDiscounts: number;

  @ApiProperty({ description: 'VAT-applicable sales (VAT-exclusive amount)', example: 17000.89 })
  vatSales: number;

  @ApiProperty({ description: 'VAT amount collected', example: 2041.11 })
  vatAmount: number;

  @ApiProperty({ description: 'Sales from VAT-exempt orders (Senior/PWD)', example: 2008.0 })
  vatExemptSales: number;

  @ApiProperty({ description: 'Total cash collected', example: 12450.0 })
  cashCollected: number;

  @ApiProperty({ description: 'Total quantity of items sold', example: 187 })
  totalQuantitySold: number;

  @ApiProperty({
    description: 'Supplementary per-cashier breakdown, sorted by sales total descending',
    type: ZReadingCashierBreakdownDto,
    isArray: true,
  })
  salesByCashier: ZReadingCashierBreakdownDto[];
}

export class ZReadingHistoryItemDto {
  @ApiProperty({ description: 'Report id', example: '0198f2b1-7c3a-7c3a-8b1a-2f6e9c1d4a10' })
  id: string;

  @ApiProperty({ description: 'Z-counter', example: 14 })
  zCounter: number;

  @ApiProperty({
    description: 'Earliest transaction covered by this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-14T22:00:00.000Z',
  })
  periodStart: string | null;

  @ApiProperty({
    description: 'Latest transaction covered by this report, if any (ISO 8601)',
    nullable: true,
    example: '2026-07-15T13:45:00.000Z',
  })
  periodEnd: string | null;

  @ApiProperty({ description: 'When this report was closed/generated (ISO 8601)' })
  generatedAt: string;

  @ApiProperty({ description: 'Total sales for this report', example: 19050.0 })
  totalSales: number;

  @ApiProperty({ description: 'Grand cumulative total as of this close', example: 171390.0 })
  endingBalance: number;

  @ApiProperty({ description: 'Completed transactions in this report', example: 42 })
  completedTransactions: number;
}
