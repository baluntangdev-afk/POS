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
