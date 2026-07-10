/**
 * Raw row from hourly/daily sales report query (SUM/COUNT from DB may be string).
 */
export interface SalesByPeriodRawRow {
  date: string | Date;
  total?: string | number | null;
  transactions?: string | number | null;
  items?: string | number | null;
  discount?: string | number | null;
}

/**
 * Raw result from total sales report query (SUM/COUNT may come as string from the driver).
 */
export interface SalesReportRawRow {
  totalSales?: string | number | null;
  totalDiscount?: string | number | null;
  totalRefunds?: string | number | null;
  totalItems?: string | number | null;
  totalTransactions?: string | number | null;
  totalVoidedTransactions?: string | number | null;
  totalVoidedAmount?: string | number | null;
}

/**
 * Raw row for product group / product / user sales reports (id, name, totalSales from DB).
 */
export interface IdNameTotalSalesRawRow {
  id: number;
  name: string;
  totalSales: string;
}

/**
 * Raw row for payment method sales report (name from enum, totalSales from DB; id assigned in mapper).
 */
export interface PaymentMethodSalesRawRow {
  name: string;
  totalSales: string;
}

/**
 * Raw row shared by cashier X-Reading's payment-method and discount breakdowns (name + summed amount).
 */
export interface NameAmountRawRow {
  name: string;
  amount?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's order-level aggregates (totals, discounts, completed count, avg/high/low).
 */
export interface CashierSalesTotalsRawRow {
  totalSales?: string | number | null;
  totalDiscounts?: string | number | null;
  completedTransactions?: string | number | null;
  averageSale?: string | number | null;
  highestSale?: string | number | null;
  lowestSale?: string | number | null;
  periodStart?: Date | string | null;
  periodEnd?: Date | string | null;
}

/**
 * Raw row for cashier X-Reading's voided-order count.
 */
export interface CashierVoidedRawRow {
  voidedTransactions?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's refunded-order count.
 */
export interface CashierRefundedRawRow {
  refundedTransactions?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's non-exempt VAT totals.
 */
export interface CashierTaxRawRow {
  vatSales?: string | number | null;
  vatAmount?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's VAT-exempt sales total.
 */
export interface CashierVatExemptRawRow {
  vatExemptSales?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's total quantity sold.
 */
export interface CashierQuantityRawRow {
  totalQuantitySold?: string | number | null;
}

/**
 * Raw row for cashier X-Reading's itemized per-payment ledger (one row per Payment record).
 */
export interface CashierPaymentLedgerRawRow {
  name: string;
  paymentDate: Date;
  transactionReference: string | null;
  amount?: string | number | null;
}

/**
 * Raw row for cashier daily report's per-product sales breakdown.
 */
export interface CashierProductSalesRawRow {
  productName: string;
  quantity?: string | number | null;
  amount?: string | number | null;
}

/**
 * Raw row for cashier daily report's cash totals (sum + count of Cash payments).
 */
export interface CashierCashSalesRawRow {
  totalCashSales?: string | number | null;
  cashSalesCount?: string | number | null;
}
