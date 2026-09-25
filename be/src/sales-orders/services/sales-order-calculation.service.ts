import { Injectable } from '@nestjs/common';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { CreateSalesOrderDto } from '../dto/create-sales-order/create-sales-order.dto';
import { OrderTotalsResult } from '../sales-order.interface';
import { TaxCategoriesService } from '../../tax-categories/tax-categories.service';
import { SalesOrderDiscountPersistenceService } from './sales-order-discount-persistence.service';
import { SalesOrderDiscount } from '../entities/sales-order-discount.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';

const DEFAULT_TAX_CATEGORY_NAME = '12% VAT';

/**
 * Discount name that made a sale VAT-exempt *before* Senior Citizen / PWD
 * stopped being VAT-exempt. New Senior/PWD sales are VATable (the discount is a
 * flat 20% off the VAT-inclusive price); reports still use this name, together
 * with the sale's zero `tax_amount`, to keep classifying those older sales as
 * VAT-exempt. See [LEGACY_VAT_EXEMPT_SALE_SQL].
 */
export const VAT_EXEMPT_DISCOUNT_NAME_PATTERNS = 'Senior Citizen / PWD';

/**
 * SQL predicate (on a `so` sales-order alias, bound to `:vatExemptName`) that
 * matches a sale saved as VAT-exempt: it carries the Senior Citizen / PWD
 * discount *and* was charged no VAT. Senior/PWD sales made after the discount
 * stopped being VAT-exempt carry VAT, so they don't match.
 */
export const LEGACY_VAT_EXEMPT_SALE_SQL =
  'so.tax_amount = 0 AND EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)';

/**
 * All numeric formulas for sales orders: subtotal, discount, tax, order totals.
 * Single place to extend for new calculation rules.
 */
@Injectable()
export class SalesOrderCalculationService {
  constructor(
    private readonly taxCategoriesService: TaxCategoriesService,
    private readonly salesOrderDiscountPersistence: SalesOrderDiscountPersistenceService,
  ) {}

  /**
   * Calculates all amounts from sales order items.
   */
  calculateAmounts(items: SalesOrderItem[]): {
    discountAmount: number;
    vatAmount: number;
    subtotal: number;
    totalAmount: number;
  } {
    const raw = items.reduce(
      (acc, item) => ({
        discountAmount: acc.discountAmount + toDecimalNumber(item.itemDiscountedPrice),
        vatAmount: acc.vatAmount + toDecimalNumber(item.vatAmount),
        subtotal: acc.subtotal + toDecimalNumber(item.itemSubtotal),
        totalAmount: acc.totalAmount + toDecimalNumber(item.itemTotalAmount),
      }),
      { discountAmount: 0, vatAmount: 0, subtotal: 0, totalAmount: 0 },
    );
    return {
      discountAmount: toDecimalNumber(raw.discountAmount),
      vatAmount: toDecimalNumber(raw.vatAmount),
      subtotal: toDecimalNumber(raw.subtotal),
      totalAmount: toDecimalNumber(raw.totalAmount),
    };
  }

  /**
   * Applies discount rate to amount; returns discount and amount after discount.
   */
  calculateDiscount(
    amount: number,
    discountRatePercent: number,
  ): {
    discountRate: number;
    discountAmount: number;
    amountAfterDiscount: number;
    amountBeforeDiscount: number;
  } {
    const discountAmount = amount * (discountRatePercent / 100);
    return {
      discountRate: discountRatePercent,
      discountAmount,
      amountBeforeDiscount: amount,
      amountAfterDiscount: amount - discountAmount,
    };
  }

  /**
   * Recalculates order totals from sales order items: subtotal, discount, tax, and final amount.
   */
  calculateOrderTotals(
    salesOrderItems: SalesOrderItem[],
    discountRatePercent: number,
    taxRatePercent: number,
  ): OrderTotalsResult {
    const { discountAmount, vatAmount, subtotal, totalAmount } =
      this.calculateAmounts(salesOrderItems);

    return {
      subtotal,
      discountRate: discountRatePercent,
      discountAmount,
      taxRate: taxRatePercent,
      taxAmount: vatAmount,
      finalTotalAmount: totalAmount,
    };
  }

  /**
   * Sums discount rate from sales order discounts (each discount.value as rate). Returns 0 if none.
   */
  getDiscountRateFromSalesOrderDiscounts(salesOrderDiscounts: SalesOrderDiscount[]): number {
    if (!salesOrderDiscounts?.length) return 0;

    const uniqueDiscounts = new Map(
      salesOrderDiscounts.map((sod) => [sod.discount?.name, sod.discount?.value]),
    );

    return Array.from(uniqueDiscounts.values()).reduce(
      (sum, value) => sum + parseFloat(value ?? '0'),
      0,
    );
  }

  /**
   * Resolves default tax and discount rates. When soId is provided, loads order discounts:
   * discountRate = sum of discount.value; taxRate is always the default VAT (no discount,
   * Senior Citizen / PWD included, makes a sale VAT-exempt).
   * additionalSalesOrderDiscounts are merged in (e.g. not-yet-saved discounts when applying a new discount).
   */
  async getDefaultOrderRates(
    soId?: string,
    additionalSalesOrderDiscounts?: SalesOrderDiscount[],
  ): Promise<{ taxRate: number; discountRate: number }> {
    const defaultTaxValue =
      await this.taxCategoriesService.findValueByName(DEFAULT_TAX_CATEGORY_NAME);
    const defaultTaxRate = parseFloat(defaultTaxValue);

    let salesOrderDiscounts: SalesOrderDiscount[] = [];
    if (soId) {
      salesOrderDiscounts =
        await this.salesOrderDiscountPersistence.findSalesOrderDiscountsBySoId(soId);
    }

    if (additionalSalesOrderDiscounts?.length) {
      const existingNames = new Set(
        salesOrderDiscounts.map((sod) => sod.discount?.name).filter(Boolean),
      );

      const newDiscounts = additionalSalesOrderDiscounts.filter((sod) => {
        const name = sod.discount?.name;
        if (!name || existingNames.has(name)) return false;
        existingNames.add(name);
        return true;
      });

      salesOrderDiscounts = [...salesOrderDiscounts, ...newDiscounts];
    }

    const discountRate = this.getDiscountRateFromSalesOrderDiscounts(salesOrderDiscounts);
    return { taxRate: defaultTaxRate, discountRate };
  }

  /**
   * Computes order totals and assigns them to the DTO. Uses default rates when options not provided.
   * Pass options.soId to derive the discount rate from that order's discounts.
   * Pass options.additionalSalesOrderDiscounts when applying new discounts not yet persisted.
   */
  async applyOrderTotalsToDto(
    dto: CreateSalesOrderDto,
    items: SalesOrderItem[],
    options?: {
      taxRate?: number;
      discountRate?: number;
      soId?: string;
      additionalSalesOrderDiscounts?: SalesOrderDiscount[];
    },
  ): Promise<void> {
    const defaults = await this.getDefaultOrderRates(
      options?.soId,
      options?.additionalSalesOrderDiscounts,
    );
    const taxRate = defaults.taxRate;
    const discountRate = defaults.discountRate;
    const totals = this.calculateOrderTotals(items, discountRate, taxRate);
    dto.totalAmount = totals.subtotal;
    dto.discountRate = totals.discountRate;
    dto.discountAmount = totals.discountAmount;
    dto.taxRate = totals.taxRate;
    dto.taxAmount = totals.taxRate === 0 ? 0 : totals.taxAmount;
    dto.finalTotalAmount = totals.finalTotalAmount;
  }
}
