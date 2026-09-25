import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { Refund } from '../../refunds/entities/refund.entity';

/**
 * The "Existing Data Found → Transfer" action: resets every sale and refund
 * to unsynced and stamps every sale with [storeId], so the next sync pushes
 * this device's full history to the now-active merchant. Only offered when
 * the device's previous merchant was never verified (an unregistered
 * merchant), mirroring mobile `TransactionSyncService.unsyncAll`.
 */
@Injectable()
export class TransferTransactionsService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async execute(storeId: string): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      await manager
        .createQueryBuilder()
        .update(SalesOrder)
        .set({ storeId, syncedAt: null })
        .execute();
      await manager.createQueryBuilder().update(Refund).set({ syncedAt: null }).execute();
    });
  }
}
