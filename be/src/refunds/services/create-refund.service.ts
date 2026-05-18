import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateRefundDto } from '../dto/create-refund.dto';
import { User } from '../../users/entities/user.entity';
import { Refund } from '../entities/refund.entity';
import { RefundValidationService } from './refund-validation.service';
import { RefundPersistenceService } from './refund-persistence.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { RefundCreatedEvent } from '../events/refund-created.event';
import { RefundsEvents } from '../events';
import { RefundWithItemsResponseDto } from '../dto/refund-with-items-response.dto';
import { RefundWithItemsMapper } from '../mapper/refund-with-items.mapper';
import dayjs from 'dayjs';
import { getKioskNo } from '../../utils/file.helper';

@Injectable()
export class CreateRefundService {
  constructor(
    @InjectRepository(Refund)
    private readonly refundRepository: Repository<Refund>,
    private readonly validation: RefundValidationService,
    private readonly persistence: RefundPersistenceService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(dto: CreateRefundDto, causer: User): Promise<RefundWithItemsResponseDto> {
    dto.refundNumber = await this.generateRefundNumber();
    dto.refundDate = dayjs().toDate();
    dto.createdBy = causer;
    dto.updatedBy = causer;

    await this.validation.validateSalesOrderExists(dto.originalSalesOrderId);

    await this.validation.validateRefundItems(dto.refundItems, dto.originalSalesOrderId);

    const { savedRefund, savedRefundItems } = await this.refundRepository.manager.transaction(
      async (transactionalEntityManager) => {
        const savedRefund = await this.persistence.saveRefund(dto, transactionalEntityManager);

        const savedRefundItems = await this.persistence.saveRefundItems(
          savedRefund.id,
          dto.refundItems,
          transactionalEntityManager,
        );

        return { savedRefund, savedRefundItems };
      },
    );

    savedRefund.refundItems = savedRefundItems;

    const eventItems = savedRefundItems.map((item) => ({
      refundItemId: item.id,
      salesOrderItemId: item.salesOrderItem.id,
      quantity: item.quantity,
      refundAmount: parseFloat(item.refundAmount),
      restockInventory: item.restockInventory,
    }));

    this.eventEmitter.emit(
      RefundsEvents.REFUND_CREATED,
      new RefundCreatedEvent(savedRefund.id, {
        items: eventItems,
        causer,
      }),
    );

    return RefundWithItemsMapper.toResponse(savedRefund);
  }

  private async generateRefundNumber(): Promise<string> {
    const currentYear = dayjs().format('YYYY');
    const kioskNo = getKioskNo();
    const prefix = `REFUND-${kioskNo.padStart(3, '0')}-${currentYear}`;

    const lastRefundNumber = await this.refundRepository
      .createQueryBuilder('refund')
      .select('refund.refundNumber')
      .where('refund.refundNumber LIKE :prefix', { prefix: `${prefix}%` })
      .orderBy('refund.refundNumber', 'DESC')
      .withDeleted()
      .getOne();

    if (!lastRefundNumber) {
      return `${prefix}-0001`;
    }

    const lastFour = lastRefundNumber.refundNumber.slice(-4);
    const lastRefundNumberInt = parseInt(lastFour, 10);
    const nextRefundNumberInt = lastRefundNumberInt + 1;

    return `${prefix}-${nextRefundNumberInt.toString().padStart(4, '0')}`;
  }
}
