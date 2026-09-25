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

/** Name of the Senior Citizen / PWD discount record. */
export const SENIOR_PWD_DISCOUNT_NAME = 'Senior Citizen / PWD';

export class ApplyDiscountToItemMapper {
  /**
   * Discount amounts for one sales order line. Senior Citizen / PWD is taken
   * off the VAT-inclusive [grossAmount] (see [computeSeniorPwdAmounts]); every
   * other discount keeps the VAT-exclusive formula of
   * [computeItemDiscountAmounts]. [appliedAmount] is what's recorded on the
   * line's `so_discounts` row.
   */
  static computeLineDiscount(
    discount: Discount,
    line: { vatExclusiveAmount: number; grossAmount: number; qty: number },
  ): { amounts: ItemDiscountAmounts; appliedAmount: string } {
    if (discount.name === SENIOR_PWD_DISCOUNT_NAME) {
      const amounts = ApplyDiscountToItemMapper.computeSeniorPwdAmounts(
        parseFloat(discount.value),
        line.grossAmount,
      );
      return { amounts, appliedAmount: amounts.discountedUnitPrice };
    }

    const amounts = ApplyDiscountToItemMapper.computeItemDiscountAmounts(
      discount,
      line.vatExclusiveAmount,
    );
    const appliedAmount = ApplyDiscountToItemMapper.computeAppliedAmount(
      line.vatExclusiveAmount,
      amounts.discountedUnitPrice,
      line.qty,
    );
    return { amounts, appliedAmount };
  }

  /**
   * Senior Citizen / PWD: a flat [ratePercent] off the full VAT-inclusive
   * price, with no VAT exemption. VAT is carried by what the customer pays:
   * VATable = net / 1.12, VAT = net − VATable. The discount is rounded to
   * centavos, same as the kiosk.
   *
   * e.g. 112.00 → discount 22.40 → net 89.60 = VATable 80.00 + VAT 9.60.
   */
  static computeSeniorPwdAmounts(ratePercent: number, grossAmount: number): ItemDiscountAmounts {
    const discountAmount = Math.round((grossAmount * (ratePercent / 100) + Number.EPSILON) * 100) / 100;
    const netAmount = parseFloat((grossAmount - discountAmount).toFixed(DECIMAL_PLACES));
    const vatableAmount = parseFloat((netAmount / (1 + TAX_RATE_PERCENT / 100)).toFixed(DECIMAL_PLACES));

    return {
      discountedUnitPrice: discountAmount.toFixed(DECIMAL_PLACES),
      subTotalAmount: vatableAmount.toFixed(DECIMAL_PLACES),
      totalAmount: netAmount.toFixed(DECIMAL_PLACES),
      vatAmount: (netAmount - vatableAmount).toFixed(DECIMAL_PLACES),
    };
  }

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

    const vatAmount = calculateLineItemVatAmount(parseFloat(subTotalAmount), TAX_RATE_PERCENT);

    const totalAmount = calculateLineItemTotalAmount(
      parseFloat(vatAmount),
      parseFloat(subTotalAmount),
    );

    return { discountedUnitPrice, subTotalAmount, totalAmount, vatAmount };
  }

  /**
   * Applies discount fields to a sales order item (mutates the item). Beneficiary fields are only
   * set when provided (Senior Citizen/PWD discounts); otherwise they're left null.
   */
  static applyDiscountAmountsToItem(
    item: SalesOrderItem,
    itemDiscountRate: number,
    amounts: ItemDiscountAmounts,
    causer: User,
    beneficiary?: { idNumber?: string; beneficiaryName?: string },
  ): void {
    item.itemDiscountRate = itemDiscountRate.toFixed(DECIMAL_PLACES);
    item.itemDiscountedPrice = amounts.discountedUnitPrice;
    item.itemTotalAmount = amounts.totalAmount;
    item.vatAmount = amounts.vatAmount;
    item.itemSubtotal = amounts.subTotalAmount;
    item.itemTotalAmount = amounts.totalAmount;
    item.discountBeneficiaryIdNumber = beneficiary?.idNumber ?? null;
    item.discountBeneficiaryName = beneficiary?.beneficiaryName ?? null;
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
