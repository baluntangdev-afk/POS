import { toDecimalNumber } from '../../utils/calculation.helper';
import { PaymentMethodSalesDataItemDto } from '../dto/payment-sales-response.dto';
import type { PaymentMethodSalesRawRow } from '../reports.interface';

/** Stable id per payment method name (enum has no table id). */
const PAYMENT_METHOD_IDS: Record<string, number> = {
  Cash: 1,
  'Credit Card': 2,
  GCash: 3,
  Other: 4,
};

/**
 * Maps a raw row to PaymentMethodSalesDataItemDto (id from map, name, totalSales with 2 decimals).
 */
export function toPaymentMethodSalesItemDto(
  row: PaymentMethodSalesRawRow,
): PaymentMethodSalesDataItemDto {
  return {
    id: PAYMENT_METHOD_IDS[row.name] ?? 0,
    name: row.name,
    totalSales: toDecimalNumber(row.totalSales),
  };
}
