/**
 * Tax category seed data.
 */
export interface TaxCategoryFixtureItem {
  name: string;
  /** Tax rate (e.g. "0" for 0%, "12" for 12%). */
  value: string;
}

export const TAX_CATEGORIES_FIXTURE: TaxCategoryFixtureItem[] = [
  { name: 'VAT-exempt', value: '0' },
  { name: '12% VAT', value: '12' },
];
