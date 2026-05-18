/**
 * Currency seed data.
 */
export interface CurrencyFixtureItem {
  code: string;
  name: string;
  sign: string | null;
  isDefault: boolean;
}

export const CURRENCIES_FIXTURE: CurrencyFixtureItem[] = [
  {
    code: 'PHP',
    name: 'Philippine Peso',
    sign: '₱',
    isDefault: true,
  },
];
