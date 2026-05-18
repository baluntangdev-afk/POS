/**
 * One material that has insufficient stock.
 */
export interface InsufficientItemDto {
  materialId: number;
  required: number;
  onHand: number;
}

/**
 * Result of validating material demands against current inventory.
 */
export interface InventoryValidationResult {
  sufficient: boolean;
  insufficientItems?: InsufficientItemDto[];
}
