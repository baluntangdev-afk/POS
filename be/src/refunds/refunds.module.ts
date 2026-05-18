import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { RefundsService } from './refunds.service';
import { RefundsController } from './refunds.controller';
import { Refund } from './entities/refund.entity';
import { RefundItem } from './entities/refund-item.entity';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { SalesOrder } from '../sales-orders/entities/sales-order.entity';
import { CreateRefundService } from './services/create-refund.service';
import { RefundValidationService } from './services/refund-validation.service';
import { RefundPersistenceService } from './services/refund-persistence.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Refund, RefundItem, SalesOrderItem, SalesOrder]),
    EventEmitterModule.forRoot(),
  ],
  controllers: [RefundsController],
  providers: [
    RefundsService,
    CreateRefundService,
    RefundValidationService,
    RefundPersistenceService,
  ],
})
export class RefundsModule {}
