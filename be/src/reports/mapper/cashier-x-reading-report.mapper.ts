import dayjs from 'dayjs';
import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import {
  CashierXReadingResponseDto,
  NameAmountDto,
  PaymentLedgerDto,
} from '../dto/cashier-x-reading-response.dto';
import { DATE_FORMAT } from '../reports.constants';
import type {
  CashierPaymentLedgerRawRow,
  CashierQuantityRawRow,
  CashierRefundedRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
  CashierVoidedRawRow,
  NameAmountRawRow,
} from '../reports.interface';

/** Inputs gathered by CashierXReadingReportService before mapping to the response DTO. */
export interface CashierXReadingRawInputs {
  currentUser: User;
  paymentRows: NameAmountRawRow[];
  paymentLedgerRows: CashierPaymentLedgerRawRow[];
  discountRows: NameAmountRawRow[];
  salesTotals: CashierSalesTotalsRawRow | undefined;
  voided: CashierVoidedRawRow | undefined;
  refunded: CashierRefundedRawRow | undefined;
  tax: CashierTaxRawRow | undefined;
  vatExempt: CashierVatExemptRawRow | undefined;
  quantity: CashierQuantityRawRow | undefined;
}

/**
 * Maps the parallel query results for the cashier X-Reading report into a single response DTO.
 * All money/count fields default to 0 when the underlying query returned no rows.
 */
export class CashierXReadingReportMapper {
  static toDto(raw: CashierXReadingRawInputs): CashierXReadingResponseDto {
    const { currentUser } = raw;
    const cashierName = `${currentUser.firstName} ${currentUser.lastName}`.trim();
    const terminalName =
      currentUser.posTerminal?.legalName ?? currentUser.posTerminal?.kioskId ?? 'Unassigned';

    const salesByPaymentMethod = raw.paymentRows.map(toNameAmountDto);
    const paymentLedgers = toPaymentLedgers(raw.paymentLedgerRows);
    const discounts = raw.discountRows.map(toNameAmountDto);

    const completedTransactions = toDecimalNumber(raw.salesTotals?.completedTransactions, 0);
    const voidedTransactions = toDecimalNumber(raw.voided?.voidedTransactions, 0);
    const cashCollected = salesByPaymentMethod.find((row) => row.name === 'Cash')?.amount ?? 0;

    return {
      cashierName,
      terminalName,
      businessDate: dayjs().format(DATE_FORMAT),
      reportGeneratedAt: new Date().toISOString(),
      salesByPaymentMethod,
      paymentLedgers,
      totalSales: toDecimalNumber(raw.salesTotals?.totalSales),
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
      averageSale: toDecimalNumber(raw.salesTotals?.averageSale),
      highestSale: toDecimalNumber(raw.salesTotals?.highestSale),
      lowestSale: toDecimalNumber(raw.salesTotals?.lowestSale),
      totalQuantitySold: toDecimalNumber(raw.quantity?.totalQuantitySold, 0),
    };
  }
}

function toNameAmountDto(row: NameAmountRawRow): NameAmountDto {
  return { name: row.name, amount: toDecimalNumber(row.amount) };
}

/** Groups itemized payment rows by name into per-method ledgers, sorted by total descending. */
function toPaymentLedgers(rows: CashierPaymentLedgerRawRow[]): PaymentLedgerDto[] {
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
