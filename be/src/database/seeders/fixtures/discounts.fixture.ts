import { DiscountType } from '../../../discounts/discounts.enum';

/**
 * Discount seed data.
 */
export interface DiscountFixtureItem {
  /** Display name / code (e.g. SC, PWD). */
  name: string;
  /** percentage | fixed_amount */
  type: DiscountType;
  /** Discount value (e.g. 20 for 20%, or fixed amount). */
  value: string;
}

export const DISCOUNTS_FIXTURE: DiscountFixtureItem[] = [
  { name: 'Senior Citizen / PWD', type: DiscountType.PERCENTAGE, value: '20' },
  { name: 'KAPENA', type: DiscountType.PERCENTAGE, value: '5' },
];
