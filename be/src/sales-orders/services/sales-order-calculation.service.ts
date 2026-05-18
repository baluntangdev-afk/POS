import { Injectable } from '@nestjs/common';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { CreateSalesOrderDto } from '../dto/create-sales-order/create-sales-order.dto';
import { OrderTotalsResult } from '../sales-order.interface';
import { TaxCategoriesService } from '../../tax-categories/tax-categories.service';
import { SalesOrderDiscountPersistenceService } from './sales-order-discount-persistence.service';
import { SalesOrderDiscount } from '../entities/sales-order-discount.entity';
import { toDecimalNumber } from '../../utils/calculation.helper';

const DEFAULT_TAX_CATEGORY_NAME = '12% VAT';

/** Discount names that imply VAT exemption (e.g. Senior Citizen / PWD). */
const VAT_EXEMPT_DISCOUNT_NAME_PATTERNS = 'Senior Citizen / PWD';

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
   * Returns true if any sales order discount is a VAT-exempt type (e.g. PWD / Senior Citizen).
   */
  isVatExempt(salesOrderDiscounts: SalesOrderDiscount[]): boolean {
    if (!salesOrderDiscounts?.length) return false;

    return salesOrderDiscounts.some(
      (sod) => VAT_EXEMPT_DISCOUNT_NAME_PATTERNS === sod.discount?.name,
    );
  }

  /**
   * Resolves default tax and discount rates. When soId is provided, loads order discounts:
   * discountRate = sum of discount.value; taxRate = 0 if any PWD/Senior discount, else default VAT.
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
    const taxRate = this.isVatExempt(salesOrderDiscounts) ? 0 : defaultTaxRate;
    return { taxRate, discountRate };
  }

  /**
   * Computes order totals and assigns them to the DTO. Uses default rates when options not provided.
   * Pass options.soId to derive tax and discount rates from that order's discounts (VAT exempt if PWD/Senior).
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
