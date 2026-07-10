import { ApiProperty } from '@nestjs/swagger';

export class NameAmountDto {
  @ApiProperty({ description: 'Name (payment method or discount name)', example: 'Cash' })
  name: string;

  @ApiProperty({ description: 'Summed amount for this name', example: 12450.0 })
  amount: number;
}

export class PaymentLedgerEntryDto {
  @ApiProperty({
    description: 'Payment timestamp (ISO 8601)',
    example: '2026-07-09T11:28:00.000Z',
  })
  time: string;

  @ApiProperty({
    description: 'Transaction reference number, if any',
    example: '278252216',
    nullable: true,
  })
  reference: string | null;

  @ApiProperty({ description: 'Amount paid for this transaction', example: 405.0 })
  amount: number;
}

export class PaymentLedgerDto {
  @ApiProperty({ description: 'Payment method name', example: 'GCash' })
  name: string;

  @ApiProperty({ description: 'Sum of all entries for this payment method', example: 3351.43 })
  total: number;

  @ApiProperty({ description: 'Number of entries for this payment method', example: 17 })
  count: number;

  @ApiProperty({
    description: 'Itemized payments, oldest first',
    type: PaymentLedgerEntryDto,
    isArray: true,
  })
  entries: PaymentLedgerEntryDto[];
}

export class CashierXReadingResponseDto {
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
    example: '2026-07-09T14:32:10.000Z',
  })
  reportGeneratedAt: string;

  @ApiProperty({
    description: 'Sales grouped by payment method',
    type: NameAmountDto,
    isArray: true,
  })
  salesByPaymentMethod: NameAmountDto[];

  @ApiProperty({
    description: 'Itemized payment ledgers, one per payment method, sorted by total descending',
    type: PaymentLedgerDto,
    isArray: true,
  })
  paymentLedgers: PaymentLedgerDto[];

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
    description: 'Discounts grouped by discount name',
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

  @ApiProperty({
    description: 'Total cash collected (also the Cash entry in salesByPaymentMethod)',
    example: 12450.0,
  })
  cashCollected: number;

  @ApiProperty({ description: 'Average sale amount', example: 453.57 })
  averageSale: number;

  @ApiProperty({ description: 'Highest single sale amount', example: 1250.0 })
  highestSale: number;

  @ApiProperty({ description: 'Lowest single sale amount', example: 85.0 })
  lowestSale: number;

  @ApiProperty({ description: 'Total quantity of items sold', example: 187 })
  totalQuantitySold: number;
}

export class CashierXReadingHistoryItemDto {
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

  @ApiProperty({ description: 'Total sales for this report', example: 19050.0 })
  totalSales: number;

  @ApiProperty({ description: 'Completed transactions in this report', example: 42 })
  completedTransactions: number;
}
