export interface ModifierGroupFixtureItem {
  name: string;
  description: string;
  selectionType: 'single' | 'multiple';
  isRequired: boolean;
  minSelection: number;
  maxSelection: number;
}

export const MODIFIER_GROUPS_FIXTURE: ModifierGroupFixtureItem[] = [
  {
    name: 'Size',
    description: 'Choose your size',
    selectionType: 'single',
    isRequired: true,
    minSelection: 1,
    maxSelection: 1,
  },
  {
    name: 'Spice Level',
    description: 'How spicy do you like it?',
    selectionType: 'single',
    isRequired: false,
    minSelection: 0,
    maxSelection: 1,
  },
  {
    name: 'Add-Ons',
    description: 'Customise your meal',
    selectionType: 'multiple',
    isRequired: false,
    minSelection: 0,
    maxSelection: 5,
  },
  {
    name: 'Sauce',
    description: 'Choose a dipping sauce',
    selectionType: 'single',
    isRequired: false,
    minSelection: 0,
    maxSelection: 1,
  },
  {
    name: 'Sugar Level',
    description: 'Choose your sugar level',
    selectionType: 'single',
    isRequired: true,
    minSelection: 1,
    maxSelection: 1,
  },
  {
    name: 'Temperature',
    description: 'Choose your preferred temperature',
    selectionType: 'single',
    isRequired: true,
    minSelection: 1,
    maxSelection: 1,
  },
  {
    name: 'Beverage Add-Ons',
    description: 'Customise your beverage',
    selectionType: 'multiple',
    isRequired: false,
    minSelection: 0,
    maxSelection: 5,
  },
  {
    name: 'Add Syrup',
    description: 'Add a flavoured syrup',
    selectionType: 'multiple',
    isRequired: false,
    minSelection: 0,
    maxSelection: 3,
  },
  {
    name: 'Add Drink',
    description: 'Add a drink to your meal',
    selectionType: 'single',
    isRequired: false,
    minSelection: 0,
    maxSelection: 1,
  },
];
