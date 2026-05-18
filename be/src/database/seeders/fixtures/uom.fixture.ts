/**
 * UOM seed data (no images).
 */
export interface UomFixtureItem {
  code: string;
  name: string;
}

export const UOM_FIXTURE: UomFixtureItem[] = [
  // Weight
  { code: 'KG', name: 'kilogram' },
  { code: 'G', name: 'gram' },
  { code: 'MG', name: 'milligram' },
  { code: 'LB', name: 'pound' },
  { code: 'OZ', name: 'ounce' },
  // Volume
  { code: 'L', name: 'liter' },
  { code: 'ML', name: 'milliliter' },
  { code: 'GAL', name: 'gallon' },
  { code: 'CUP', name: 'cup' },
  { code: 'TBSP', name: 'tablespoon' },
  { code: 'TSP', name: 'teaspoon' },
  // Count / Pieces
  { code: 'PCS', name: 'pieces' },
  { code: 'EA', name: 'each' },
  { code: 'DOZ', name: 'dozen' },
  { code: 'BOX', name: 'box' },
  { code: 'PACK', name: 'pack' },
  { code: 'CTN', name: 'carton' },
  // Length / Size (packaging, wraps)
  { code: 'M', name: 'meter' },
  { code: 'CM', name: 'centimeter' },
  { code: 'MM', name: 'millimeter' },
  // Service / Portion-based (very F&B)
  { code: 'SERV', name: 'serving' },
  { code: 'SHOT', name: 'espresso shot' },
  { code: 'CUP_S', name: 'serving cup' },
];
