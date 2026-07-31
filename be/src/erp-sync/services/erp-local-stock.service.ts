import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../products/entities/product.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderEvents } from '../../sales-orders/events';
import { OrderConfirmedEvent } from '../../sales-orders/events/order-confirmed.event';
import { AppConfigService } from '../../config/config.service';

/**
 * Keeps a local remaining-servings counter for ERP-managed products so the
 * kiosk stops selling as soon as local stock hits zero — without waiting for
 * the next 5-minute ERP menu sync. ERP remains the source of truth on sync
 * and on order push (shortage → 409).
 */
@Injectable()
export class ErpLocalStockService {
  private readonly logger = new Logger(ErpLocalStockService.name);

  constructor(
    private readonly config: AppConfigService,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {}

  @OnEvent(SalesOrderEvents.ORDER_CONFIRMED)
  async handleOrderConfirmed(event: OrderConfirmedEvent): Promise<void> {
    if (!this.config.erpSyncEnabled) return;

    const items = await this.salesOrderItemRepository.find({
      where: { salesOrder: { id: event.soId } },
      relations: { productVariant: { product: true } },
    });

    const qtyByProductId = new Map<number, number>();
    for (const item of items) {
      if (item.addOn) continue;
      const product = item.productVariant?.product;
      if (!product?.sku || product.availableServings == null) continue;
      const qty = Number(item.qty) || 0;
      if (qty <= 0) continue;
      qtyByProductId.set(product.id, (qtyByProductId.get(product.id) ?? 0) + qty);
    }

    for (const [productId, qty] of qtyByProductId) {
      await this.decrementServings(productId, qty);
    }
  }

  /**
   * Atomically reduce remaining servings and flip is_available when the count
   * reaches zero. Concurrent confirmations cannot oversell the local counter.
   */
  private async decrementServings(productId: number, qty: number): Promise<void> {
    const result = await this.productRepository.query(
      `
      UPDATE products
      SET
        available_servings = GREATEST(COALESCE(available_servings, 0) - $1, 0),
        is_available = (GREATEST(COALESCE(available_servings, 0) - $1, 0) > 0),
        updated_at = NOW()
      WHERE id = $2
        AND sku IS NOT NULL
        AND available_servings IS NOT NULL
        AND deleted_at IS NULL
      RETURNING id, sku, available_servings, is_available
      `,
      [qty, productId],
    );

    const row = Array.isArray(result) ? result[0] : null;
    if (row) {
      this.logger.log(
        `Local stock ${row.sku}: servings=${row.available_servings}, available=${row.is_available}`,
      );
    }
  }
}
