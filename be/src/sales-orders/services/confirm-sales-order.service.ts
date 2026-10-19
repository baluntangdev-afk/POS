import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../entities/sales-order.entity';
import { SalesOrderStatus } from '../sales-orders.enum';
import { ConfirmSalesOrderDto } from '../dto/confirm-sales-order/confirm-sales-order.dto';
import { User } from '../../users/entities/user.entity';
import { PaymentDetailsToPaymentMapper } from '../../payments/mapper/payment-details-to-payment.mapper';
import { SalesOrderEvents } from '../events';
import { OrderConfirmedEvent } from '../events/order-confirmed.event';

@Injectable()
export class ConfirmSalesOrderService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(id: string, dto: ConfirmSalesOrderDto, causer: User): Promise<string> {
    const salesOrder = await this.salesOrderRepository.findOne({
      where: { id },
      select: { id: true, status: true },
    });

    if (!salesOrder) {
      throw new NotFoundException(`Sales order ${id} not found`);
    }

    if (salesOrder.status === SalesOrderStatus.CANCELLED) {
      throw new BadRequestException('Cannot confirm a cancelled sales order');
    }

    // Already confirmed (e.g. client retry): no second payment, no second event.
    if (salesOrder.status !== SalesOrderStatus.PENDING) {
      return id;
    }

    const confirmed = await this.salesOrderRepository.manager.transaction(async (manager) => {
      // The status guard makes concurrent confirms race-safe: only one update matches.
      const result = await manager.update(
        SalesOrder,
        { id, status: SalesOrderStatus.PENDING },
        {
          status: SalesOrderStatus.CONFIRMED,
          updatedBy: { id: causer.id },
          clientRequestId: dto.clientRequestId,
        },
      );

      if (!result.affected) return false;

      await manager.save(PaymentDetailsToPaymentMapper.toEntity(id, dto.payment_details));
      return true;
    });

    if (confirmed) {
      this.eventEmitter.emit(SalesOrderEvents.ORDER_CONFIRMED, new OrderConfirmedEvent(id, causer));
    }

    return id;
  }
}
