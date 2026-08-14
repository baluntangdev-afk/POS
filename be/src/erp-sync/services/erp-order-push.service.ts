import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderEvents } from '../../sales-orders/events';
import { OrderConfirmedEvent } from '../../sales-orders/events/order-confirmed.event';
import { AppConfigService } from '../../config/config.service';
import { ErpOrderPush } from '../entities/erp-order-push.entity';
import { ErpOrderPushStatus } from '../erp-sync.enum';
import { ErpClientService, ErpOrderPayload } from './erp-client.service';
import { EntityHelper } from '../../utils/entity.helper';

/**
 * Pushes confirmed orders to the ERP so it deducts ingredient stock in real time.
 * ORDER_CONFIRMED enqueues + attempts immediately; a cron retries with backoff.
 * The ERP is idempotent on client_order_id (= sales order UUID), so retries are safe.
 */
@Injectable()
export class ErpOrderPushService {
  private readonly logger = new Logger(ErpOrderPushService.name);

  private static readonly MAX_ATTEMPTS = 20;
  /** Backoff: attempts × 2 minutes between retries (capped at 30 min). */
  private static backoffMs(attempts: number): number {
    return Math.min(attempts * 2, 30) * 60 * 1000;
  }

  constructor(
    private readonly config: AppConfigService,
    private readonly erpClient: ErpClientService,
    @InjectRepository(ErpOrderPush)
    private readonly pushRepository: Repository<ErpOrderPush>,
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {}

  @OnEvent(SalesOrderEvents.ORDER_CONFIRMED)
  async handleOrderConfirmed(event: OrderConfirmedEvent): Promise<void> {
    if (!this.config.erpSyncEnabled || !this.erpClient.isConfigured) return;

    const existing = await this.pushRepository.findOne({
      where: { salesOrder: { id: event.soId } },
    });
    if (!existing) {
      await this.pushRepository.save(
        this.pushRepository.create({
          salesOrder: EntityHelper.toIdEntity<SalesOrder>(event.soId),
        }),
      );
    }

    // Try immediately; the cron picks it up again on failure.
    try {
      await this.pushOrder(event.soId);
    } catch (err) {
      this.logger.warn(`Immediate ERP push failed for ${event.soId}: ${(err as Error).message}`);
    }
  }

  /** Retry queue drain — same cadence as the other POS sync cron. */
  @Cron('*/2 * * * *')
  async retryPending(): Promise<void> {
    if (!this.config.erpSyncEnabled || !this.erpClient.isConfigured) return;

    const rows = await this.pushRepository.find({
      where: { status: In([ErpOrderPushStatus.PENDING, ErpOrderPushStatus.FAILED]) },
      relations: { salesOrder: true },
      order: { id: 'ASC' },
      take: 50,
    });

    const now = Date.now();
    for (const row of rows) {
      if (row.attempts >= ErpOrderPushService.MAX_ATTEMPTS) continue;
      if (
        row.lastAttemptAt &&
        now - row.lastAttemptAt.getTime() < ErpOrderPushService.backoffMs(row.attempts)
      )
        continue;

      try {
        await this.pushOrder(row.salesOrder.id);
      } catch (err) {
        this.logger.warn(`ERP push retry failed for ${row.salesOrder.id}: ${(err as Error).message}`);
      }
    }
  }

  /** Builds the ERP payload for one order and sends it, updating the queue row. */
  async pushOrder(soId: string): Promise<void> {
    const row = await this.pushRepository.findOne({
      where: { salesOrder: { id: soId } },
      relations: { salesOrder: true },
    });
    if (!row || row.status === ErpOrderPushStatus.SENT) return;

    const order = await this.salesOrderRepository.findOne({ where: { id: soId } });
    if (!order) {
      await this.markFailed(row, 'Sales order not found', true);
      return;
    }

    const items = await this.salesOrderItemRepository.find({
      where: { salesOrder: { id: soId } },
      relations: { productVariant: { product: true } },
      order: { itemSequence: 'ASC' },
    });

    // Only ERP-managed lines (products carrying an ERP SKU) are pushed.
    const erpLines = items
      .filter((i) => !i.addOn && i.productVariant?.product?.sku)
      .map((i) => ({
        sku: i.productVariant!.product!.sku as string,
        quantity: Number(i.qty),
        unit_price: Number(i.unitPrice),
      }));

    if (erpLines.length === 0) {
      // Nothing ERP-managed on this order — mark done so it never retries.
      row.status = ErpOrderPushStatus.SENT;
      row.sentAt = new Date();
      row.lastError = 'No ERP-managed items on order';
      await this.pushRepository.save(row);
      return;
    }

    const payload: ErpOrderPayload = {
      client_order_id: soId,
      order_no: order.soNumber,
      terminal: this.config.erpTerminalId,
      store_code: this.config.erpStoreCode || undefined,
      order_date: (order.soDate ?? order.createdAt ?? new Date()).toISOString(),
      items: erpLines,
    };

    row.attempts += 1;
    row.lastAttemptAt = new Date();

    const result = await this.erpClient.postOrder(payload);
    if (result.ok) {
      row.status = ErpOrderPushStatus.SENT;
      row.sentAt = new Date();
      row.lastError = null;
      await this.pushRepository.save(row);
      this.logger.log(`Order ${order.soNumber} pushed to ERP (stock deducted).`);
      return;
    }

    await this.markFailed(row, result.message ?? 'Unknown error', result.permanent);
  }

  private async markFailed(row: ErpOrderPush, message: string, permanent: boolean): Promise<void> {
    row.status = ErpOrderPushStatus.FAILED;
    row.lastError = message.slice(0, 2000);
    if (permanent) row.attempts = ErpOrderPushService.MAX_ATTEMPTS;
    await this.pushRepository.save(row);
  }

  async queueStatus() {
    const [pending, failed, sent] = await Promise.all([
      this.pushRepository.count({ where: { status: ErpOrderPushStatus.PENDING } }),
      this.pushRepository.count({ where: { status: ErpOrderPushStatus.FAILED } }),
      this.pushRepository.count({ where: { status: ErpOrderPushStatus.SENT } }),
    ]);
    return { pending, failed, sent };
  }
}
