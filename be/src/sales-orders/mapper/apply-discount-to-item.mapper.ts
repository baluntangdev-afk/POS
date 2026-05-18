import { User } from '../../users/entities/user.entity';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import {
  DECIMAL_PLACES,
  calculateLineItemDiscountedPrice,
  calculateLineItemSubtotal,
  calculateLineItemTotalAmount,
  calculateLineItemVatAmount,
} from '../../utils/calculation.helper';
import { ItemDiscountAmounts } from '../sales-order.interface';
import { Discount } from '../../discounts/entities/discount.entity';
import { TAX_RATE_PERCENT } from '../../utils/constants';

export class ApplyDiscountToItemMapper {
  /**
   * Computes discounted unit price and line total for an item.
   */
  static computeItemDiscountAmounts(discount: Discount, amount: number): ItemDiscountAmounts {
    const discountedUnitPrice = calculateLineItemDiscountedPrice(
      parseFloat(discount.value),
      discount.type,
      amount,
    );

    const subTotalAmount = calculateLineItemSubtotal(amount, parseFloat(discountedUnitPrice));

    const taxRate = discount.name === 'Senior Citizen / PWD' ? 0 : TAX_RATE_PERCENT;
    const vatAmount = calculateLineItemVatAmount(parseFloat(subTotalAmount), taxRate);

    const totalAmount = calculateLineItemTotalAmount(
      parseFloat(vatAmount),
      parseFloat(subTotalAmount),
    );

    return { discountedUnitPrice, subTotalAmount, totalAmount, vatAmount };
  }

  /**
   * Applies discount fields to a sales order item (mutates the item).
   */
  static applyDiscountAmountsToItem(
    item: SalesOrderItem,
    itemDiscountRate: number,
    amounts: ItemDiscountAmounts,
    causer: User,
  ): void {
    item.itemDiscountRate = itemDiscountRate.toFixed(DECIMAL_PLACES);
    item.itemDiscountedPrice = amounts.discountedUnitPrice;
    item.itemTotalAmount = amounts.totalAmount;
    item.vatAmount = amounts.vatAmount;
    item.itemSubtotal = amounts.subTotalAmount;
    item.itemTotalAmount = amounts.totalAmount;
    item.updatedBy = causer;
  }

  /**
   * Computes the total applied discount amount for a line: (unitPrice - discountedUnitPrice) × qty.
   */
  static computeAppliedAmount(unitPrice: number, discountedUnitPrice: string, qty: number): string {
    const discountPerUnit = unitPrice - parseFloat(discountedUnitPrice);
    return (discountPerUnit * qty).toFixed(DECIMAL_PLACES);
  }

  /**
   * Updates the existing item after splitting off a child: subtracts child qty and itemTotalAmount so existing represents the remaining non-discounted portion.
   */
  static updateExistingItem(
    existingItem: SalesOrderItem,
    childItem: SalesOrderItem,
    causer: User,
    isAddon: boolean,
    nextSequence: number,
  ): void {
    if (!isAddon) {
      existingItem.qty = (Number(existingItem.qty) - Number(childItem.qty)).toFixed(DECIMAL_PLACES);
      existingItem.itemTotalAmount = (
        Number(existingItem.itemTotalAmount) - Number(childItem.itemTotalAmount)
      ).toFixed(DECIMAL_PLACES);
    }
    existingItem.itemSequence = nextSequence;
    existingItem.updatedBy = causer;
  }

  /**
   * Creates a child sales order item from an existing one (for partial-qty discount line).
   */
  static toChildItemFromExisting(
    existingItem: SalesOrderItem,
    nextSequence: number,
  ): SalesOrderItem {
    const childItem = new SalesOrderItem();

    Object.assign(childItem, { ...existingItem, id: undefined });
    childItem.itemSequence = nextSequence;
    childItem.salesOrder = existingItem.salesOrder;
    childItem.parentSoItem = existingItem;

    return childItem;
  }
}
