/**
 * Materials seed data (no images). Cafe materials for coffees.
 * materialCode is generated in seeder as {materialTypeCode}{4-digit sequence}, e.g. RAW0001.
 */
export interface MaterialFixtureItem {
  materialName: string;
  /** Material type code (e.g. RAW, PKG, CNS) */
  materialTypeCode: string;
  /** Standard base UOM code (e.g. G, ML, PCS) */
  standardBaseUnitCode: string;
}

const SEQUENCE_LENGTH = 4;

/** Zero-pad number to 4 digits, e.g. 1 -> "0001". */
export function formatMaterialCodeSequence(sequence: number): string {
  return String(sequence).padStart(SEQUENCE_LENGTH, '0');
}

export const MATERIALS_FIXTURE: MaterialFixtureItem[] = [
  { materialName: 'Ice', materialTypeCode: 'RAW', standardBaseUnitCode: 'G' },
  { materialName: 'Coffee Beans', materialTypeCode: 'RAW', standardBaseUnitCode: 'G' },
  { materialName: 'Cup', materialTypeCode: 'PKG', standardBaseUnitCode: 'PCS' },
  { materialName: 'Straw', materialTypeCode: 'CNS', standardBaseUnitCode: 'PCS' },
  { materialName: 'Lid', materialTypeCode: 'PKG', standardBaseUnitCode: 'PCS' },
  { materialName: 'Vanilla Syrup', materialTypeCode: 'RAW', standardBaseUnitCode: 'ML' },
  { materialName: 'Caramel Syrup', materialTypeCode: 'RAW', standardBaseUnitCode: 'ML' },
  { materialName: 'Whipped Cream', materialTypeCode: 'RAW', standardBaseUnitCode: 'G' },
  { materialName: 'Whole Milk', materialTypeCode: 'RAW', standardBaseUnitCode: 'ML' },
  { materialName: 'Oat Milk', materialTypeCode: 'RAW', standardBaseUnitCode: 'ML' },
  { materialName: 'Almond Milk', materialTypeCode: 'RAW', standardBaseUnitCode: 'ML' },
  { materialName: 'Filtered water', materialTypeCode: 'RAW', standardBaseUnitCode: 'ML' },
  { materialName: 'Muffin', materialTypeCode: 'FNG', standardBaseUnitCode: 'PCS' },
  { materialName: 'Salad', materialTypeCode: 'FNG', standardBaseUnitCode: 'PCS' },
  { materialName: 'Club Sandwich', materialTypeCode: 'FNG', standardBaseUnitCode: 'PCS' },
];
