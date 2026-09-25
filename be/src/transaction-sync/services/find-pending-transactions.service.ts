import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Not, Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { Refund } from '../../refunds/entities/refund.entity';
import { TransactionSyncPayloadMapper } from '../mapper/transaction-sync-payload.mapper';
import { PendingTransactionCountsDto, PendingTransactionsDto } from '../dto/transaction-sync.dto';

const DEFAULT_BATCH_SIZE = 15;

/**
 * Reads what still has to reach the orders service. Only sales stamped with
 * [storeId] (and refunds of such sales) are returned — a sale made under a
 * merchant this device has since been reassigned away from must never be
 * pushed under the currently-active one. Unpaid (`Pending`) sales are skipped
 * until they are confirmed, mirroring the mobile app.
 */
@Injectable()
export class FindPendingTransactionsService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(Refund)
    private readonly refundRepository: Repository<Refund>,
  ) {}

  async findBatch(storeId: string, limit = DEFAULT_BATCH_SIZE): Promise<PendingTransactionsDto> {
    const sales = await this.salesOrderRepository.find({
      where: this.unsyncedSalesWhere(storeId),
      relations: {
        createdBy: true,
        payments: true,
        salesOrderItems: {
          parentSoItem: true,
          productVariant: { product: { productGroup: true } },
          salesOrderDiscount: { discount: true },
        },
      },
      order: { id: 'ASC' },
      take: limit,
    });

    const refunds = await this.refundRepository.find({
      where: { syncedAt: IsNull(), originalSalesOrder: { storeId } },
      relations: {
        originalSalesOrder: true,
        refundItems: { salesOrderItem: { productVariant: { product: { productGroup: true } } } },
      },
      order: { id: 'ASC' },
      take: limit,
    });

    const saleItemsBySaleId = await this.loadSaleItems(
      refunds.map((refund) => refund.originalSalesOrder.id),
    );

    const refundedBySaleId = await this.loadRefundedAmounts(sales.map((sale) => sale.id));

    return {
      sales: sales.map((sale) =>
        TransactionSyncPayloadMapper.toSalePayload(sale, refundedBySaleId.get(sale.id) ?? 0),
      ),
      refunds: refunds.map((refund) =>
        TransactionSyncPayloadMapper.toRefundPayload(
          refund,
          saleItemsBySaleId.get(refund.originalSalesOrder.id) ?? [],
        ),
      ),
    };
  }

  async count(storeId: string): Promise<PendingTransactionCountsDto> {
    const [sales, refunds] = await Promise.all([
      this.salesOrderRepository.count({ where: this.unsyncedSalesWhere(storeId) }),
      this.refundRepository.count({
        where: { syncedAt: IsNull(), originalSalesOrder: { storeId } },
      }),
    ]);
    return { sales, refunds };
  }

  /** True if this device has any sale or refund at all, regardless of sync state. */
  async hasAny(): Promise<boolean> {
    const [sales, refunds] = await Promise.all([
      this.salesOrderRepository.count({ take: 1 }),
      this.refundRepository.count({ take: 1 }),
    ]);
    return sales > 0 || refunds > 0;
  }

  private unsyncedSalesWhere(storeId: string) {
    return {
      syncedAt: IsNull(),
      storeId,
      status: Not(SalesOrderStatus.PENDING),
    };
  }

  /** Total refunded per sale, so a fully refunded sale is sent as `refunded`. */
  private async loadRefundedAmounts(saleIds: string[]): Promise<Map<string, number>> {
    if (saleIds.length === 0) return new Map();
    const rows: { saleId: string; total: string }[] = await this.refundRepository
      .createQueryBuilder('refund')
      .select('refund.original_sales_order_id', 'saleId')
      .addSelect('SUM(refund.total_refund_amount)', 'total')
      .where('refund.original_sales_order_id IN (:...saleIds)', { saleIds })
      .groupBy('refund.original_sales_order_id')
      .getRawMany();
    return new Map(rows.map((row) => [row.saleId, Number(row.total)]));
  }

  private async loadSaleItems(saleIds: string[]): Promise<Map<string, SalesOrderItem[]>> {
    const bySaleId = new Map<string, SalesOrderItem[]>();
    if (saleIds.length === 0) return bySaleId;

    const items = await this.salesOrderItemRepository.find({
      where: { salesOrder: { id: In([...new Set(saleIds)]) } },
      relations: { salesOrder: true, parentSoItem: true },
      order: { id: 'ASC' },
    });
    for (const item of items) {
      const list = bySaleId.get(item.salesOrder.id) ?? [];
      list.push(item);
      bySaleId.set(item.salesOrder.id, list);
    }
    return bySaleId;
  }
}
