import { Injectable } from '@nestjs/common';
import { FindPendingTransactionsService } from './services/find-pending-transactions.service';
import { MarkTransactionsSyncedService } from './services/mark-transactions-synced.service';
import { TransferTransactionsService } from './services/transfer-transactions.service';
import { UnsyncTransactionsService } from './services/unsync-transactions.service';
import {
  HasTransactionsDto,
  PendingTransactionCountsDto,
  PendingTransactionsDto,
} from './dto/transaction-sync.dto';

@Injectable()
export class TransactionSyncService {
  constructor(
    private readonly findPendingTransactionsService: FindPendingTransactionsService,
    private readonly markTransactionsSyncedService: MarkTransactionsSyncedService,
    private readonly transferTransactionsService: TransferTransactionsService,
    private readonly unsyncTransactionsService: UnsyncTransactionsService,
  ) {}

  findPending(storeId: string, limit?: number): Promise<PendingTransactionsDto> {
    return this.findPendingTransactionsService.findBatch(storeId, limit);
  }

  countPending(storeId: string): Promise<PendingTransactionCountsDto> {
    return this.findPendingTransactionsService.count(storeId);
  }

  async hasTransactions(): Promise<HasTransactionsDto> {
    return { hasTransactions: await this.findPendingTransactionsService.hasAny() };
  }

  markSynced(saleIds: number[], refundIds: number[]): Promise<void> {
    return this.markTransactionsSyncedService.execute(saleIds, refundIds);
  }

  transfer(storeId: string): Promise<void> {
    return this.transferTransactionsService.execute(storeId);
  }

  unsync(): Promise<void> {
    return this.unsyncTransactionsService.execute();
  }
}
