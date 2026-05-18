/**
 * Shape of one item in the OrderCreatedEvent payload.
 */
export interface OrderCreatedEventItemDto {
  soItemId: string;
  productVariantId: number;
  recipeId: number;
  quantity: number;
  recipeItemId?: number;
  isAddOn: boolean;
}
