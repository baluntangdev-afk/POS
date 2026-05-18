import { SalesOrderStatus } from '../sales-orders/sales-orders.enum';

/** Dayjs format for date (e.g. 02/16/2026). */
export const DATE_FORMAT = 'MM/DD/YYYY';

/** Dayjs format for hour in 12h (e.g. 01:00 PM). */
export const HOUR_FORMAT = 'hh:mm A';

/** Status filter for sales orders. */
export const STATUS_FILTER = [SalesOrderStatus.CONFIRMED, SalesOrderStatus.COMPLETED];

/** Allowed sort directions for totalSales (product / product group reports). */
export const SORT_VALUES = ['DESC', 'ASC'] as const;

/** Sort direction for totalSales (product / product group reports). */
export type ProductGroupSalesSort = (typeof SORT_VALUES)[number];
