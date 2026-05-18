import { Injectable } from '@nestjs/common';
import { SalesOrder } from '../entities/sales-order.entity';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { ConfirmSalesOrderDto } from '../dto/confirm-sales-order/confirm-sales-order.dto';
import { User } from '../../users/entities/user.entity';
import { PaymentDetailsToPaymentMapper } from '../../payments/mapper/payment-details-to-payment.mapper';
import { SalesOrderStatus } from '../sales-orders.enum';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SalesOrderEvents } from '../events';
import { OrderConfirmedEvent } from '../events/order-confirmed.event';

@Injectable()
export class ConfirmSalesOrderService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(soId: string, confirmSalesOrderDto: ConfirmSalesOrderDto, causer: User) {
    const salesOrder = this.salesOrderRepository.create({
      id: soId,
      status: SalesOrderStatus.CONFIRMED,
      updatedBy: causer,
    });

    const payment = PaymentDetailsToPaymentMapper.toEntity(
      soId,
      confirmSalesOrderDto.payment_details,
    );

    await this.salesOrderRepository.manager.transaction(async (transactionalEntityManager) => {
      await transactionalEntityManager.save(salesOrder);
      await transactionalEntityManager.save(payment);
    });

    this.eventEmitter.emit(SalesOrderEvents.ORDER_CONFIRMED, new OrderConfirmedEvent(soId, causer));

    return soId;
  }
}
