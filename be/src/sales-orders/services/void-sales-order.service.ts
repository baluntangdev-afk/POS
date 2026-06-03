import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SalesOrder } from '../entities/sales-order.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrderStatus } from '../sales-orders.enum';
import { UserRole } from '../../users/users.enum';
import { VoidSalesOrderDto } from '../dto/void-sales-order.dto';
import { SalesOrderEvents } from '../events';
import { OrderVoidedEvent } from '../events/order-voided.event';

@Injectable()
export class VoidSalesOrderService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(soId: string, dto: VoidSalesOrderDto): Promise<string> {
    const salesOrder = await this.salesOrderRepository.findOne({ where: { id: soId } });

    if (!salesOrder) {
      throw new NotFoundException('Sales order not found');
    }

    if (salesOrder.status === SalesOrderStatus.CANCELLED) {
      throw new BadRequestException('This transaction has already been voided');
    }

    const authorizer = await this.userRepository.findOne({
      where: { userId: dto.authorizer_user_id },
    });

    if (!authorizer) {
      throw new NotFoundException('Authorizer user not found');
    }

    const canAuthorize =
      authorizer.systemAdmin ||
      authorizer.role === UserRole.ADMIN ||
      authorizer.role === UserRole.SUPERVISOR;

    if (!canAuthorize) {
      throw new ForbiddenException('Only admins and supervisors can authorize a void');
    }

    const isPinValid = await bcrypt.compare(dto.authorizer_pin, authorizer.devicePin);

    if (!isPinValid) {
      throw new BadRequestException('Invalid PIN. Please try again.');
    }

    await this.salesOrderRepository.save(
      this.salesOrderRepository.create({
        id: soId,
        status: SalesOrderStatus.CANCELLED,
        voidReason: dto.reason,
        voidedBy: authorizer,
        voidedAt: new Date(),
      }),
    );

    this.eventEmitter.emit(
      SalesOrderEvents.ORDER_VOIDED,
      new OrderVoidedEvent(soId, authorizer),
    );

    return soId;
  }
}
