import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiNoContentResponse, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
import { TransactionSyncService } from './transaction-sync.service';
import {
  HasTransactionsDto,
  MarkTransactionsSyncedDto,
  PendingTransactionCountsDto,
  PendingTransactionsDto,
  PendingTransactionsQueryDto,
  StoreIdQueryDto,
  TransferTransactionsDto,
} from './dto/transaction-sync.dto';

/**
 * Local sync-state bookkeeping for the kiosk app, which pushes sales/refunds
 * to the external orders service (`POST /merchant/transactions/sync`) itself.
 * This backend only hands out ready-to-send batches and records what the
 * orders service accepted.
 */
@ApiTags('Transaction Sync')
@Controller('transaction-sync')
export class TransactionSyncController {
  constructor(private readonly transactionSyncService: TransactionSyncService) {}

  @Get('pending')
  @ApiOperation({ summary: 'Next batch of unsynced sales/refunds for a store, in wire format' })
  @ApiOkResponse({ type: PendingTransactionsDto })
  findPending(@Query() query: PendingTransactionsQueryDto) {
    return this.transactionSyncService.findPending(query.storeId, query.limit);
  }

  @Get('pending/count')
  @ApiOperation({ summary: 'Number of unsynced sales/refunds for a store' })
  @ApiOkResponse({ type: PendingTransactionCountsDto })
  countPending(@Query() query: StoreIdQueryDto) {
    return this.transactionSyncService.countPending(query.storeId);
  }

  @Get('has-transactions')
  @ApiOperation({ summary: 'Whether this device has any sale or refund at all' })
  @ApiOkResponse({ type: HasTransactionsDto })
  hasTransactions() {
    return this.transactionSyncService.hasTransactions();
  }

  @Post('mark-synced')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Mark sales/refunds the orders service accepted as synced' })
  @ApiNoContentResponse()
  markSynced(@Body() dto: MarkTransactionsSyncedDto) {
    return this.transactionSyncService.markSynced(dto.saleIds, dto.refundIds);
  }

  @Post('transfer')
  @UseGuards(AdminOrSupervisorGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Re-queue every sale/refund and reassign all sales to the given store',
  })
  @ApiNoContentResponse()
  transfer(@Body() dto: TransferTransactionsDto) {
    return this.transactionSyncService.transfer(dto.storeId);
  }
}
