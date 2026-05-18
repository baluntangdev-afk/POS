/** Report mappers. */
export { SalesReportMapper } from './sales-report.mapper';
export { toHourlySalesDataItemDto } from './hourly-sales-report.mapper';
export { toDailySalesDataItemDto } from './daily-sales-report.mapper';
export { toMonthlySalesDataItemDto } from './monthly-sales-report.mapper';
export { toProductGroupSalesItemDto } from './product-group-sales-report.mapper';
export { toProductSalesItemDto } from './product-sales-report.mapper';
export { toUserSalesItemDto } from './user-sales-report.mapper';
export { toPaymentMethodSalesItemDto } from './payment-sales-report.mapper';
export type {
  SalesReportRawRow,
  IdNameTotalSalesRawRow,
  PaymentMethodSalesRawRow,
} from '../reports.interface';
