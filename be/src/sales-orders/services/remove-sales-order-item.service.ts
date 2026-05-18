import { Injectable } from '@nestjs/common';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SalesOrderCalculationService } from './sales-order-calculation.service';
import { SalesOrderItemsPersistenceService } from './sales-order-items-persistence.service';
import { RemoveSalesOrderItemDto } from '../dto/remove-sales-order.dto';
import { SalesOrdersService } from '../sales-orders.service';
import { CreateSalesOrderMapper } from '../mapper/create-sales-order.mapper';
import { SalesOrderEvents } from '../events';
import { OrderItemRemovedEvent } from '../events/order-item-removed.event';

@Injectable()
export class RemoveSalesOrderItemService {
  constructor(
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    private readonly itemsPersistence: SalesOrderItemsPersistenceService,
    private readonly calculation: SalesOrderCalculationService,
    private readonly salesOrdersService: SalesOrdersService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(dto: RemoveSalesOrderItemDto) {
    await this.itemsPersistence.validateSalesOrderItemExists(dto.soItemId);
    const salesOrder = await this.salesOrdersService.findOneWithoutItems(dto.id);
    const createDto = CreateSalesOrderMapper.toDto(salesOrder);

    const [itemSequence, currentSavedItems, oldSoItemIds] = await Promise.all([
      this.itemsPersistence.getItemSequence(dto.soItemId),
      this.itemsPersistence.findSalesOrderItemsBySoId(dto.id!, dto.soItemId),
      this.itemsPersistence.getSoItemIdsOfTheSameSequence(dto.id!, dto.soItemId),
    ]);

    await this.calculation.applyOrderTotalsToDto(createDto, currentSavedItems, {
      soId: dto.id,
    });

    const recalculatedSalesOrder = CreateSalesOrderMapper.toEntity(createDto);

    await this.salesOrderItemRepository.manager.transaction(async (transactionalEntityManager) => {
      await transactionalEntityManager.save(recalculatedSalesOrder);
      await transactionalEntityManager.softDelete(SalesOrderItem, {
        itemSequence: itemSequence,
        salesOrder: { id: dto.id },
      });
    });

    this.eventEmitter.emit(
      SalesOrderEvents.ORDER_ITEM_REMOVED,
      new OrderItemRemovedEvent(dto.id, {
        soItemIds: oldSoItemIds,
        causer: dto.deletedBy,
      }),
    );
  }
}
