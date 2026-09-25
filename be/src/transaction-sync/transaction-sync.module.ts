import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SalesOrder } from '../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { Refund } from '../refunds/entities/refund.entity';
import { TransactionSyncController } from './transaction-sync.controller';
import { TransactionSyncService } from './transaction-sync.service';
import { FindPendingTransactionsService } from './services/find-pending-transactions.service';
import { MarkTransactionsSyncedService } from './services/mark-transactions-synced.service';
import { TransferTransactionsService } from './services/transfer-transactions.service';
import { UnsyncTransactionsService } from './services/unsync-transactions.service';

@Module({
  imports: [TypeOrmModule.forFeature([SalesOrder, SalesOrderItem, Refund])],
  controllers: [TransactionSyncController],
  providers: [
    TransactionSyncService,
    FindPendingTransactionsService,
    MarkTransactionsSyncedService,
    TransferTransactionsService,
    UnsyncTransactionsService,
  ],
})
export class TransactionSyncModule {}
