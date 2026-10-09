import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../entities/sales-order.entity';
import { SalesOrderStatus } from '../sales-orders.enum';
import { ConfirmSalesOrderDto } from '../dto/confirm-sales-order/confirm-sales-order.dto';
import { Payment } from '../../payments/entities/payment.entity';
import { SalesOrderEvents } from '../events';

@Injectable()
export class ConfirmSalesOrderService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(id: string, confirmSalesOrderDto: ConfirmSalesOrderDto): Promise<SalesOrder> {
    const salesOrder = await this.salesOrderRepository.findOne({
      where: { id },
      relations: ['items'],
    });

    if (!salesOrder) {
      throw new Error('Sales order not found');
    }

    if (salesOrder.status === SalesOrderStatus.CONFIRMED) {
      return salesOrder;
    }

    if (salesOrder.status === SalesOrderStatus.CANCELLED) {
      throw new Error('Cannot confirm a cancelled sales order');
    }

    await this.salesOrderRepository.manager.transaction(async (manager) => {
      await manager.update(
        SalesOrder,
        { id },
        {
          status: SalesOrderStatus.CONFIRMED,
          clientRequestId:
            confirmSalesOrderDto.clientRequestId ?? (salesOrder as any).clientRequestId,
        },
      );
    });

    this.eventEmitter.emit(SalesOrderEvents.ORDER_CONFIRMED, { orderId: id });
    return salesOrder;
  }
}
