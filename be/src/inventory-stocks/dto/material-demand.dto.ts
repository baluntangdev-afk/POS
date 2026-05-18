/**
 * Input for inventory availability validation: one required material quantity in a given unit.
 */
export interface MaterialDemandDto {
  materialId: number;
  quantity: number;
  unitId: number;
}
