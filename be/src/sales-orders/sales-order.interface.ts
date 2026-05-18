import type { SalesOrderItem } from './entities/sales-order-item.entity';
import type { Discount } from '../discounts/entities/discount.entity';
import type { ProductVariant } from '../products/entities/product-variant.entity';
import type { ModifierOption } from '../modifier-groups/entities/modifier-option.entity';

/** Result of recalculating order totals from items (subtotal, discount, tax, final). */
export interface OrderTotalsResult {
  subtotal: number;
  discountRate: number;
  discountAmount: number;
  taxRate: number;
  taxAmount: number;
  finalTotalAmount: number;
}

/** Result of computing discount amounts for a line item. */
export interface ItemDiscountAmounts {
  discountedUnitPrice: string;
  subTotalAmount: string;
  totalAmount: string;
  vatAmount: string;
}

/** Lookup data for building sales order items from create DTO. */
export interface LookupData {
  recipeIds: Map<number, number>;
  productVariants: Map<number, ProductVariant>;
  modifierOptionMap: Map<number, ModifierOption>;
}

/** Result of resolving discount context for an apply-discount line item. */
export interface ResolveDiscountContextResult {
  existingItem: SalesOrderItem;
  discount: Discount;
  soId: string;
  unitPrice: number;
  vatExclusiveAmount: number;
  qty: number;
  discountValue: number;
  amounts: ItemDiscountAmounts;
  appliedAmount: string;
}
