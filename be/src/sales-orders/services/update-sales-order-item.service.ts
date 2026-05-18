import { Injectable } from '@nestjs/common';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { CreateSalesOrderMapper } from '../mapper/create-sales-order.mapper';
import { SalesOrderEvents } from '../events';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { UpdateSalesOrderDto } from '../dto/update-sales-order.dto';
import { OrderCreatedEventMapper } from '../mapper/order-created-event.mapper';
import { OrderUpdatedEvent } from '../events/order-update.event';
import { SalesOrderCalculationService } from './sales-order-calculation.service';
import { SalesOrderItemBuildService } from './sales-order-item-build.service';
import { SalesOrderInventoryValidationService } from './sales-order-inventory-validation.service';
import { SalesOrderItemsPersistenceService } from './sales-order-items-persistence.service';

@Injectable()
export class UpdateSalesOrderItemService {
  constructor(
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    private readonly itemBuild: SalesOrderItemBuildService,
    private readonly inventoryValidation: SalesOrderInventoryValidationService,
    private readonly itemsPersistence: SalesOrderItemsPersistenceService,
    private readonly calculation: SalesOrderCalculationService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(dto: UpdateSalesOrderDto, causer: User): Promise<string> {
    dto.createdBy = causer;
    dto.updatedBy = causer;

    await this.itemsPersistence.validateSalesOrderItemExists(dto.soItemId);

    const [itemSequence, currentSavedItems, oldSoItemIds, { salesOrderItems }] = await Promise.all([
      this.itemsPersistence.getItemSequence(dto.soItemId),
      this.itemsPersistence.findSalesOrderItemsBySoId(dto.id!, dto.soItemId),
      this.itemsPersistence.getSoItemIdsOfTheSameSequence(dto.id!, dto.soItemId),
      this.itemBuild.generateSalesOrderItems(dto.products, causer, dto.id, dto.soItemId),
    ]);

    await this.inventoryValidation.validateInventoryAvailability(salesOrderItems);
    await this.calculation.applyOrderTotalsToDto(dto, [...currentSavedItems, ...salesOrderItems], {
      soId: dto.id,
    });

    const salesOrder = CreateSalesOrderMapper.toEntity(dto);

    const { savedSo, savedSoItems } = await this.salesOrderItemRepository.manager.transaction(
      async (transactionalEntityManager) => {
        const savedSo = await transactionalEntityManager.save(salesOrder);
        await transactionalEntityManager.softDelete(SalesOrderItem, {
          itemSequence: itemSequence,
          salesOrder: { id: dto.id },
        });
        const savedSoItems = await this.itemsPersistence.saveSalesOrderItems(
          savedSo.id,
          salesOrderItems,
          transactionalEntityManager,
        );
        return { savedSo, savedSoItems };
      },
    );

    this.eventEmitter.emit(
      SalesOrderEvents.ORDER_UPDATE,
      new OrderUpdatedEvent(savedSo.id, {
        items: OrderCreatedEventMapper.toEventItems(savedSoItems),
        oldSoItemIds: oldSoItemIds,
        causer,
      }),
    );

    return savedSo.id;
  }
}
