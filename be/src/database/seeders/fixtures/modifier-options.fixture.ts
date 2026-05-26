export interface ModifierOptionFixtureItem {
  name: string;
  priceAddOn: string;
  sortOrder: number;
  isAvailable: boolean;
}

export interface ModifierOptionsGroupFixture {
  modifierGroupName: string;
  options: ModifierOptionFixtureItem[];
}

export const MODIFIER_OPTIONS_FIXTURE: ModifierOptionsGroupFixture[] = [
  {
    modifierGroupName: 'Size',
    options: [
      { name: 'Regular',     priceAddOn: '0.00',  sortOrder: 0, isAvailable: true },
      { name: 'Large',       priceAddOn: '25.00', sortOrder: 1, isAvailable: true },
      { name: 'Extra Large', priceAddOn: '45.00', sortOrder: 2, isAvailable: true },
    ],
  },
  {
    modifierGroupName: 'Spice Level',
    options: [
      { name: 'Mild',   priceAddOn: '0.00', sortOrder: 0, isAvailable: true },
      { name: 'Medium', priceAddOn: '0.00', sortOrder: 1, isAvailable: true },
      { name: 'Hot',    priceAddOn: '0.00', sortOrder: 2, isAvailable: true },
    ],
  },
  {
    modifierGroupName: 'Add-ons',
    options: [
      { name: 'Extra Cheese', priceAddOn: '15.00', sortOrder: 0, isAvailable: true },
      { name: 'Bacon',        priceAddOn: '25.00', sortOrder: 1, isAvailable: true },
      { name: 'Fried Egg',    priceAddOn: '20.00', sortOrder: 2, isAvailable: true },
      { name: 'Avocado',      priceAddOn: '30.00', sortOrder: 3, isAvailable: true },
      { name: 'Jalapeños',    priceAddOn: '10.00', sortOrder: 4, isAvailable: true },
    ],
  },
  {
    modifierGroupName: 'Sauce',
    options: [
      { name: 'Ketchup',   priceAddOn: '0.00', sortOrder: 0, isAvailable: true },
      { name: 'Mustard',   priceAddOn: '0.00', sortOrder: 1, isAvailable: true },
      { name: 'Aioli',     priceAddOn: '0.00', sortOrder: 2, isAvailable: true },
      { name: 'BBQ Sauce', priceAddOn: '0.00', sortOrder: 3, isAvailable: true },
      { name: 'Hot Sauce', priceAddOn: '0.00', sortOrder: 4, isAvailable: true },
    ],
  },
  {
    modifierGroupName: 'Sugar Level',
    options: [
      { name: '0%',   priceAddOn: '0.00', sortOrder: 0, isAvailable: true },
      { name: '25%',  priceAddOn: '0.00', sortOrder: 1, isAvailable: true },
      { name: '50%',  priceAddOn: '0.00', sortOrder: 2, isAvailable: true },
      { name: '75%',  priceAddOn: '0.00', sortOrder: 3, isAvailable: true },
      { name: '100%', priceAddOn: '0.00', sortOrder: 4, isAvailable: true },
    ],
  },
  {
    modifierGroupName: 'Temperature',
    options: [
      { name: 'Hot',  priceAddOn: '0.00', sortOrder: 0, isAvailable: true },
      { name: 'Cold', priceAddOn: '0.00', sortOrder: 1, isAvailable: true },
    ],
  },
];
