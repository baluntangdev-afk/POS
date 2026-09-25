import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { Refund } from '../../refunds/entities/refund.entity';
import { PaymentMethod } from '../../payments/payments.enum';
import { SalesOrderStatus, SalesOrderType } from '../../sales-orders/sales-orders.enum';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';

/**
 * Builds the `sales[]` / `refunds[]` records of the orders service's
 * `POST /merchant/transactions/sync` body, in the exact wire shape the mobile
 * app sends (see mobile `SalesDao.getSaleSyncPayload` / `getRefundSyncPayload`),
 * so the kiosk can forward them verbatim.
 *
 * The orders service validates records against the mobile app's model, so
 * values are translated to it: `local_id` is the sale's integer `syncId` (the
 * UUID primary key is rejected), and `status` / `type` use mobile's
 * lowercase vocabulary.
 *
 * Kiosk sales model modifiers/add-ons as child line items (`parent_so_item_id`)
 * rather than a separate table, so only top-level items become `items[]` and
 * their children become each item's `modifiers[]`.
 */
export class TransactionSyncPayloadMapper {
  /**
   * Whether [sale] was saved as VAT-exempt: it has a Senior Citizen / PWD line
   * and was charged no VAT. Mirrors the reports' `LEGACY_VAT_EXEMPT_SALE_SQL`.
   */
  static isLegacyVatExemptSale(sale: SalesOrder): boolean {
    if (Number(sale.taxAmount ?? 0) !== 0) return false;
    return (sale.salesOrderItems ?? []).some(
      (item) => item.salesOrderDiscount?.discount?.name === VAT_EXEMPT_DISCOUNT_NAME_PATTERNS,
    );
  }

  /** [refundedAmount] is the sum of every refund against [sale]. */
  static toSalePayload(sale: SalesOrder, refundedAmount = 0): Record<string, unknown> {
    const items = TransactionSyncPayloadMapper.topLevelItems(sale.salesOrderItems ?? []);
    const children = sale.salesOrderItems ?? [];
    const isLegacyVatExempt = TransactionSyncPayloadMapper.isLegacyVatExemptSale(sale);

    return {
      local_id: sale.syncId,
      so_number: sale.soNumber,
      cashier_name: TransactionSyncPayloadMapper.userName(sale.createdBy),
      created_at: sale.createdAt.toISOString(),
      type: TransactionSyncPayloadMapper.saleType(sale.soType),
      status: TransactionSyncPayloadMapper.saleStatus(sale, refundedAmount),
      total: Number(sale.finalTotalAmount),
      discount: Number(sale.discountAmount),
      void_reason: sale.voidReason,
      voided_at: sale.voidedAt?.toISOString() ?? null,
      items: items.map((item) => {
        const discount = item.salesOrderDiscount;
        const qty = Number(item.qty);
        return {
          product_name: item.productVariant?.product?.name ?? item.description,
          category_name: item.productVariant?.product?.productGroup?.name ?? null,
          variant_name: item.productVariant?.name ?? null,
          qty,
          unit_price: Number(item.unitPrice),
          discount_type: discount?.discount?.name ?? null,
          discount_beneficiary_id: item.discountBeneficiaryIdNumber,
          discount_beneficiary_name: item.discountBeneficiaryName,
          discount_amount: Number(item.itemDiscountedPrice ?? 0),
          // Only sales saved while Senior Citizen / PWD was VAT-exempt carry a
          // VAT-exempt figure; newer Senior/PWD sales are VATable.
          vat_exempt_amount: isLegacyVatExempt && discount ? Number(item.vatAmount ?? 0) : 0,
          modifiers: children
            .filter((child) => child.parentSoItem?.id === item.id)
            .map((child) => ({
              name: child.description,
              additional_price: Number(child.unitPrice),
            })),
        };
      }),
      payments: (sale.payments ?? []).map((payment) => {
        const tendered = Number(payment.amountPaid);
        const change = Number(payment.change ?? 0);
        return {
          method: payment.paymentMethodName || payment.paymentMethod,
          amount: tendered - change,
          cash_received: payment.paymentMethod === PaymentMethod.CASH ? tendered : null,
          reference: payment.transactionReference,
        };
      }),
    };
  }

  /**
   * [saleItems] are all line items of the refunded sale; `sale_item_index`
   * is the refunded item's position among its top-level items, matching the
   * order of the sale payload's `items[]`.
   */
  static toRefundPayload(refund: Refund, saleItems: SalesOrderItem[]): Record<string, unknown> {
    const sale = refund.originalSalesOrder;
    const topLevel = TransactionSyncPayloadMapper.topLevelItems(saleItems);
    const indexByItemId = new Map(topLevel.map((item, index) => [item.id, index]));

    return {
      local_id: refund.id,
      refund_number: refund.refundNumber,
      sale_local_id: sale.syncId,
      sale_so_number: sale.soNumber,
      reason: refund.reason,
      method: refund.paymentMethod,
      total: Number(refund.totalRefundAmount),
      created_at: refund.createdAt.toISOString(),
      items: (refund.refundItems ?? []).map((refundItem) => {
        const item = refundItem.salesOrderItem;
        return {
          sale_item_index: indexByItemId.get(item.id) ?? 0,
          product_name: item.productVariant?.product?.name ?? item.description,
          category_name: item.productVariant?.product?.productGroup?.name ?? null,
          qty: refundItem.quantity,
          amount: Number(refundItem.refundAmount),
        };
      }),
    };
  }

  /** Mobile's sale statuses: `completed` | `voided` | `refunded`. */
  private static saleStatus(sale: SalesOrder, refundedAmount: number): string {
    if (sale.status === SalesOrderStatus.CANCELLED) return 'voided';
    const total = Number(sale.finalTotalAmount);
    if (total > 0 && refundedAmount >= total) return 'refunded';
    return 'completed';
  }

  /** Mobile's sale types: `dine_in` | `take_out` | `delivery`. */
  private static saleType(type: SalesOrderType): string {
    switch (type) {
      case SalesOrderType.TAKE_OUT:
        return 'take_out';
      case SalesOrderType.DELIVERY:
        return 'delivery';
      default:
        return 'dine_in';
    }
  }

  private static topLevelItems(items: SalesOrderItem[]): SalesOrderItem[] {
    // UUIDv7 ids sort chronologically, i.e. in the order the items were added.
    return items
      .filter((item) => !item.parentSoItem)
      .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  }

  private static userName(user: SalesOrder['createdBy'] | null | undefined): string {
    const name = [user?.firstName, user?.lastName].filter(Boolean).join(' ').trim();
    return name || 'Unknown';
  }
}
