/**
 * Material type seed data (no images).
 */
export interface MaterialTypeFixtureItem {
  materialTypeCode: string;
  materialTypeName: string;
  autoMaterialCode: boolean;
}

export const MATERIAL_TYPES_FIXTURE: MaterialTypeFixtureItem[] = [
  {
    materialTypeCode: 'RAW',
    materialTypeName: 'Raw materials / ingredients',
    autoMaterialCode: true,
  },
  {
    materialTypeCode: 'SFG',
    materialTypeName: 'Semi-finished / prepped items',
    autoMaterialCode: true,
  },
  {
    materialTypeCode: 'FNG',
    materialTypeName: 'Finished goods (sellable)',
    autoMaterialCode: true,
  },
  {
    materialTypeCode: 'PKG',
    materialTypeName: 'Packaging (cups, lids)',
    autoMaterialCode: true,
  },
  {
    materialTypeCode: 'CNS',
    materialTypeName: 'Consumables (napkins, gloves)',
    autoMaterialCode: true,
  },
];
