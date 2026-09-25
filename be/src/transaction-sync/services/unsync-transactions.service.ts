import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { Refund } from '../../refunds/entities/refund.entity';

/**
 * The Transactions screen's "Unsync Transactions" action: resets every sale
 * and refund to unsynced so the next sync re-uploads the full history. Unlike
 * [TransferTransactionsService], each sale keeps its own `store_id`, mirroring
 * mobile `TransactionSyncService.unsyncAllKeepingStoreId`.
 */
@Injectable()
export class UnsyncTransactionsService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async execute(): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      await manager.createQueryBuilder().update(SalesOrder).set({ syncedAt: null }).execute();
      await manager.createQueryBuilder().update(Refund).set({ syncedAt: null }).execute();
    });
  }
}
