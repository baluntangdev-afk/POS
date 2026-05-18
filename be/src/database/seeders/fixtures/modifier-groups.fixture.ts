/**
 * Modifier group seed data.
 */
export interface ModifierGroupFixtureItem {
  name: string;
  minSelection?: number;
  maxSelection?: number;
}

export const MODIFIER_GROUPS_FIXTURE: ModifierGroupFixtureItem[] = [
  { name: 'Add-Ons' },
  { name: 'Add Drink' },
  { name: 'Temperature', minSelection: 1, maxSelection: 1 },
  { name: 'Add Syrup', minSelection: 0, maxSelection: 1 },
];
