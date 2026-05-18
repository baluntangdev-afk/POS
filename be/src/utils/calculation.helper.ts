import { DiscountType } from '../discounts/discounts.enum';
import { TAX_RATE_PERCENT } from './constants';

export const DECIMAL_PLACES = 6;

/**
 * Parses a value to a number rounded to the given decimal places. Returns 0 for null, undefined, or invalid numbers.
 */
export function toDecimalNumber(
  value: string | number | null | undefined,
  decimalPlaces: number = DECIMAL_PLACES,
): number {
  if (value == null) return 0;
  const n = typeof value === 'string' ? parseFloat(value) : value;
  if (!Number.isFinite(n)) return 0;
  const factor = 10 ** decimalPlaces;
  return Math.round(n * factor) / factor;
}

/**
 * Pure function: computes line item total amount. Used by mapper and service so formula stays in one place.
 */
export function calculateLineItemTotalAmount(vatAmount: number, itemSubtotal: number): string {
  return (vatAmount + itemSubtotal).toFixed(DECIMAL_PLACES);
}

export function calculateLineItemVatExclusiveAmount(
  quantity: number,
  unitPrice: number,
  vatRatePercent: number = TAX_RATE_PERCENT,
): string {
  const vatRate = vatRatePercent / 100;
  const raw = (quantity * unitPrice) / (1 + vatRate);
  return raw.toFixed(DECIMAL_PLACES);
}

export function calculateLineItemVatAmount(
  subtotal: number,
  vatRatePercent: number = TAX_RATE_PERCENT,
): string {
  const vatRate = vatRatePercent / 100;
  const raw = subtotal * vatRate;
  return raw.toFixed(DECIMAL_PLACES);
}

export function calculateLineItemSubtotal(
  vatExclusiveAmount: number,
  discountAmount: number,
): string {
  return (vatExclusiveAmount - discountAmount).toFixed(DECIMAL_PLACES);
}

export function calculateLineItemDiscountedPrice(
  discountRate: number,
  discountType: DiscountType,
  amount: number,
): string {
  if (discountType === DiscountType.PERCENTAGE) {
    return (amount * (discountRate / 100)).toFixed(DECIMAL_PLACES);
  } else {
    return (amount - discountRate).toFixed(DECIMAL_PLACES);
  }
}
