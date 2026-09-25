import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, In } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { Refund } from '../../refunds/entities/refund.entity';

/**
 * Records the ids the orders service durably accepted — sale `syncId`s
 * (sent as `local_id`) and refund ids. Anything sent but not
 * listed stays unsynced and is retried on the next sync run.
 */
@Injectable()
export class MarkTransactionsSyncedService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async execute(saleIds: number[], refundIds: number[]): Promise<void> {
    if (saleIds.length === 0 && refundIds.length === 0) return;
    const now = new Date();

    await this.dataSource.transaction(async (manager) => {
      if (saleIds.length > 0) {
        await manager.update(SalesOrder, { syncId: In(saleIds) }, { syncedAt: now });
      }
      if (refundIds.length > 0) {
        await manager.update(Refund, { id: In(refundIds) }, { syncedAt: now });
      }
    });
  }
}
