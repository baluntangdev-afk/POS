import { toDecimalNumber } from '../../utils/calculation.helper';
import { NameAmountDto, PaymentLedgerDto } from '../dto/cashier-x-reading-response.dto';
import {
  ItemSalesDto,
  ZReadingCashierBreakdownDto,
  ZReadingResponseDto,
} from '../dto/z-reading-response.dto';
import type {
  CashierPaymentLedgerRawRow,
  CashierQuantityRawRow,
  CashierRefundedRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
  CashierVoidedRawRow,
  ItemSalesRawRow,
  NameAmountRawRow,
  ZReadingCashierBreakdownRawRow,
} from '../reports.interface';

/** Inputs gathered by ZReadingReportService before mapping to the response DTO. */
export interface ZReadingRawInputs {
  terminalName: string;
  paymentRows: NameAmountRawRow[];
  paymentLedgerRows: CashierPaymentLedgerRawRow[];
  itemRows: ItemSalesRawRow[];
  discountRows: NameAmountRawRow[];
  salesTotals: CashierSalesTotalsRawRow | undefined;
  voided: CashierVoidedRawRow | undefined;
  refunded: CashierRefundedRawRow | undefined;
  tax: CashierTaxRawRow | undefined;
  vatExempt: CashierVatExemptRawRow | undefined;
  quantity: CashierQuantityRawRow | undefined;
  cashierBreakdownRows: ZReadingCashierBreakdownRawRow[];
  beginningBalance: number;
}

/**
 * Maps the parallel query results for the store-wide Z-Reading report into a single response
 * DTO. All money/count fields default to 0 when the underlying query returned no rows.
 */
export class ZReadingReportMapper {
  static toDto(
    raw: ZReadingRawInputs,
    id: string | null = null,
    zCounter: number | null = null,
    closedByName: string | null = null,
    authorizedByName: string | null = null,
  ): ZReadingResponseDto {
    const salesByPaymentMethod = raw.paymentRows.map(toNameAmountDto);
    const paymentLedgers = toPaymentLedgers(raw.paymentLedgerRows);
    const salesByItem = raw.itemRows.map(toItemSalesDto);
    const discounts = raw.discountRows.map(toNameAmountDto);

    const completedTransactions = toDecimalNumber(raw.salesTotals?.completedTransactions, 0);
    const voidedTransactions = toDecimalNumber(raw.voided?.voidedTransactions, 0);
    const cashCollected = salesByPaymentMethod.find((row) => row.name === 'Cash')?.amount ?? 0;
    const totalSales = toDecimalNumber(raw.salesTotals?.totalSales);
    const beginningBalance = toDecimalNumber(raw.beginningBalance);

    return {
      id,
      zCounter,
      terminalName: raw.terminalName,
      closedByName,
      authorizedByName,
      periodStart: toIsoOrNull(raw.salesTotals?.periodStart),
      periodEnd: toIsoOrNull(raw.salesTotals?.periodEnd),
      reportGeneratedAt: new Date().toISOString(),
      beginningBalance,
      endingBalance: beginningBalance + totalSales,
      salesByPaymentMethod,
      paymentLedgers,
      salesByItem,
      totalSales,
      totalTransactions: completedTransactions + voidedTransactions,
      completedTransactions,
      voidedTransactions,
      refundedTransactions: toDecimalNumber(raw.refunded?.refundedTransactions, 0),
      discounts,
      totalDiscounts: toDecimalNumber(raw.salesTotals?.totalDiscounts),
      vatSales: toDecimalNumber(raw.tax?.vatSales),
      vatAmount: toDecimalNumber(raw.tax?.vatAmount),
      vatExemptSales: toDecimalNumber(raw.vatExempt?.vatExemptSales),
      cashCollected,
      totalQuantitySold: toDecimalNumber(raw.quantity?.totalQuantitySold, 0),
      salesByCashier: toSalesByCashier(raw.cashierBreakdownRows),
    };
  }
}

function toNameAmountDto(row: NameAmountRawRow): NameAmountDto {
  return { name: row.name, amount: toDecimalNumber(row.amount) };
}

function toItemSalesDto(row: ItemSalesRawRow): ItemSalesDto {
  return {
    name: row.name,
    quantity: toDecimalNumber(row.quantity, 0),
    amount: toDecimalNumber(row.amount),
  };
}

/** Groups itemized payment rows by name into per-method ledgers, sorted by total descending. */
export function toPaymentLedgers(rows: CashierPaymentLedgerRawRow[]): PaymentLedgerDto[] {
  const ledgersByName = new Map<string, PaymentLedgerDto>();

  for (const row of rows) {
    const amount = toDecimalNumber(row.amount);
    let ledger = ledgersByName.get(row.name);
    if (ledger == null) {
      ledger = { name: row.name, total: 0, count: 0, entries: [] };
      ledgersByName.set(row.name, ledger);
    }
    ledger.total += amount;
    ledger.count += 1;
    ledger.entries.push({
      time: new Date(row.paymentDate).toISOString(),
      reference: row.transactionReference,
      amount,
    });
  }

  return Array.from(ledgersByName.values()).sort((a, b) => b.total - a.total);
}

function toSalesByCashier(rows: ZReadingCashierBreakdownRawRow[]): ZReadingCashierBreakdownDto[] {
  return rows
    .map((row) => ({
      cashierId: row.cashierId,
      cashierName: row.cashierName,
      transactionCount: toDecimalNumber(row.transactionCount, 0),
      salesTotal: toDecimalNumber(row.salesTotal),
    }))
    .sort((a, b) => b.salesTotal - a.salesTotal);
}

function toIsoOrNull(value: Date | string | null | undefined): string | null {
  return value ? new Date(value).toISOString() : null;
}
