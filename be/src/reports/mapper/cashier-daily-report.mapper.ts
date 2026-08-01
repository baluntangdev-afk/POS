import { User } from '../../users/entities/user.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';
import {
  CashierDailyReportResponseDto,
  CashLedgerEntryDto,
  ProductSalesLineDto,
} from '../dto/cashier-daily-report-response.dto';
import type {
  CashierCashSalesRawRow,
  CashierPaymentLedgerRawRow,
  CashierProductSalesRawRow,
  CashierQuantityRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
} from '../reports.interface';

/** Inputs gathered by CashierDailyReportService before mapping to the response DTO. */
export interface CashierDailyReportRawInputs {
  currentUser: User;
  salesTotals: CashierSalesTotalsRawRow | undefined;
  tax: CashierTaxRawRow | undefined;
  vatExempt: CashierVatExemptRawRow | undefined;
  quantity: CashierQuantityRawRow | undefined;
  productRows: CashierProductSalesRawRow[];
  cashSales: CashierCashSalesRawRow | undefined;
  cashLedgerRows: CashierPaymentLedgerRawRow[];
}

/**
 * Maps the parallel query results for the cashier daily report into a single response DTO.
 * All money/count fields default to 0 when the underlying query returned no rows.
 * Zero-rated sales are not tracked by the system and are always reported as 0.
 */
export class CashierDailyReportMapper {
  static toDto(
    raw: CashierDailyReportRawInputs,
    id: string | null = null,
  ): CashierDailyReportResponseDto {
    const { currentUser } = raw;
    const cashierName = `${currentUser.firstName} ${currentUser.lastName}`.trim();
    const terminalName =
      currentUser.posTerminal?.legalName ?? currentUser.posTerminal?.kioskId ?? 'Unassigned';

    const grossSales = toDecimalNumber(raw.salesTotals?.totalSales);
    const vatAmount = toDecimalNumber(raw.tax?.vatAmount);

    return {
      id,
      cashierName,
      terminalName,
      periodStart: toIsoOrNull(raw.salesTotals?.periodStart),
      periodEnd: toIsoOrNull(raw.salesTotals?.periodEnd),
      reportGeneratedAt: new Date().toISOString(),
      grossSales,
      vatableSales: toDecimalNumber(raw.tax?.vatSales),
      vatAmount,
      vatExemptSales: toDecimalNumber(raw.vatExempt?.vatExemptSales),
      zeroRatedSales: 0,
      netOfTax: grossSales - vatAmount,
      transactionCount: toDecimalNumber(raw.salesTotals?.completedTransactions, 0),
      totalQuantity: toDecimalNumber(raw.quantity?.totalQuantitySold, 0),
      totalCashSales: toDecimalNumber(raw.cashSales?.totalCashSales),
      cashSalesCount: toDecimalNumber(raw.cashSales?.cashSalesCount, 0),
      salesByProduct: raw.productRows.map(toProductSalesLineDto),
      cashLedger: raw.cashLedgerRows.map(toCashLedgerEntryDto),
    };
  }
}

function toProductSalesLineDto(row: CashierProductSalesRawRow): ProductSalesLineDto {
  return {
    quantity: toDecimalNumber(row.quantity, 0),
    productName: row.productName,
    amount: toDecimalNumber(row.amount),
  };
}

function toCashLedgerEntryDto(row: CashierPaymentLedgerRawRow): CashLedgerEntryDto {
  return {
    time: new Date(row.paymentDate).toISOString(),
    reference: row.transactionReference,
    amount: toDecimalNumber(row.amount),
  };
}

function toIsoOrNull(value: Date | string | null | undefined): string | null {
  return value ? new Date(value).toISOString() : null;
}
